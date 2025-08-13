#!/usr/bin/env python3
import json
import re
import asyncio
import logging
import os
from typing import Any, Dict, Iterable, Tuple, Optional
from datetime import datetime
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

import ollama
from mcp import ClientSession, types as mtypes
from mcp.client.streamable_http import streamablehttp_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration from environment
MCP_URL = os.getenv("MCP_URL", "http://zabbix-mcp:8000/mcp")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:3b-instruct")

SYSTEM_PROMPT = (
    "You are a tool-using assistant for Zabbix monitoring.\n"
    'Return ONLY {"tool": "<name or null>", "arguments": {}} as strict JSON.\n'
    "Choose exactly one tool from the provided list (or null). No prose."
)

FEWSHOTS: Iterable[Tuple[str, Dict[str, Any]]] = (
    ("List recent critical problems (top 5)",
     {"tool": "problem_get", "arguments": {"recent": True, "severity": ["5"], "limit": 5}}),
    ("List all hosts",
     {"tool": "host_get", "arguments": {}}),
    ("Get API version",
     {"tool": "apiinfo_version", "arguments": {}}),
    ("Show host status",
     {"tool": "host_get", "arguments": {"output": ["hostid", "name", "status"]}}),
)

class ChatbotService:
    def __init__(self):
        self.tools_cache = None
        self.cache_timestamp = None
    
    async def get_mcp_session(self) -> ClientSession:
        """Get or create MCP session with error handling."""
        try:
            session = await streamablehttp_client(MCP_URL).__aenter__()
            # Test connection
            await session.list_tools()
            return session
        except Exception as e:
            logger.error(f"Failed to connect to MCP server: {e}")
            raise HTTPException(status_code=503, detail="MCP server unavailable")
    
    async def get_tools(self, force_refresh: bool = False) -> Dict[str, mtypes.Tool]:
        """Get tools with caching."""
        now = datetime.now()
        if (self.tools_cache is None or force_refresh or 
            (self.cache_timestamp and (now - self.cache_timestamp).seconds > 300)):
            
            async with await self.get_mcp_session() as session:
                tools_resp = await session.list_tools()
                self.tools_cache = {t.name: t for t in tools_resp.tools}
                self.cache_timestamp = now
                logger.info(f"Loaded {len(self.tools_cache)} tools from MCP server")
        
        return self.tools_cache
    
    def choose_tool_with_ollama(self, user_prompt: str, tools: Dict[str, mtypes.Tool]) -> Dict[str, Any]:
        """Use Ollama to choose appropriate tool."""
        try:
            tool_descriptions = []
            for name, tool in tools.items():
                desc = f"- {name}: {tool.description}"
                if hasattr(tool, 'inputSchema') and tool.inputSchema:
                    props = tool.inputSchema.get('properties', {})
                    if props:
                        params = ', '.join(props.keys())
                        desc += f" (params: {params})"
                tool_descriptions.append(desc)
            
            few_shot_examples = []
            for example_q, example_a in FEWSHOTS:
                few_shot_examples.append(f"Q: {example_q}\nA: {json.dumps(example_a)}")
            
            prompt = f"""{SYSTEM_PROMPT}

Available tools:
{chr(10).join(tool_descriptions)}

Examples:
{chr(10).join(few_shot_examples)}

Q: {user_prompt}
A:"""
            
            response = ollama.chat(
                model=OLLAMA_MODEL,
                messages=[{"role": "user", "content": prompt}],
                options={"temperature": 0.1}
            )
            
            content = response["message"]["content"].strip()
            return self._force_json(content) or {"tool": None, "arguments": {}}
            
        except Exception as e:
            logger.error(f"Ollama request failed: {e}")
            return {"tool": None, "arguments": {}, "error": str(e)}
    
    def _force_json(self, s: str) -> Optional[Dict[str, Any]]:
        """Extract JSON from response."""
        s = s.strip()
        if s.startswith("```json"):
            s = s[7:]
        if s.endswith("```"):
            s = s[:-3]
        
        # Try direct parsing
        try:
            return json.loads(s)
        except:
            pass
        
        # Try finding JSON in text
        json_match = re.search(r'\{[^}]+\}', s)
        if json_match:
            try:
                return json.loads(json_match.group())
            except:
                pass
        
        return None
    
    async def run_query(self, user_prompt: str) -> Dict[str, Any]:
        """Execute user query through MCP."""
        try:
            tools = await self.get_tools()
            choice = self.choose_tool_with_ollama(user_prompt, tools)
            
            tool_name = choice.get("tool")
            args = choice.get("arguments", {})
            
            if not tool_name or tool_name not in tools:
                return {
                    "choice": choice,
                    "result": None,
                    "error": "no_tool_selected",
                    "available_tools": list(tools.keys())
                }
            
            async with await self.get_mcp_session() as session:
                res = await session.call_tool(tool_name, arguments=args)
                
                if hasattr(res, 'structuredContent') and res.structuredContent:
                    payload = {"structured": res.structuredContent}
                else:
                    texts = [c.text for c in (res.content or []) if hasattr(c, "text")]
                    payload = {"text": "\n".join(texts) if texts else "No content returned"}
                
                return {
                    "choice": choice,
                    "result": payload,
                    "error": None,
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            return {
                "choice": choice if 'choice' in locals() else None,
                "result": None,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

# Initialize service
chatbot_service = ChatbotService()

# FastAPI app with lifespan
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Zabbix Chatbot Service")
    try:
        # Test connections
        await chatbot_service.get_tools()
        logger.info("Successfully connected to MCP server")
    except Exception as e:
        logger.error(f"Failed to initialize: {e}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Zabbix Chatbot Service")

app = FastAPI(title="Zabbix Chatbot", lifespan=lifespan)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", response_class=HTMLResponse)
async def index():
    return FileResponse("static/index.html")

@app.post("/chat")
async def chat(req: Request):
    try:
        body = await req.json()
        user_msg = (body.get("message") or "").strip()
        
        if not user_msg:
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        logger.info(f"Processing query: {user_msg}")
        result = await chatbot_service.run_query(user_msg)
        
        return JSONResponse(result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat endpoint error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    """Health check endpoint."""
    try:
        tools = await chatbot_service.get_tools()
        return {
            "status": "healthy",
            "mcp_connection": "ok",
            "tools_count": len(tools),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return JSONResponse(
            {"status": "unhealthy", "error": str(e)},
            status_code=503
        )

@app.get("/tools")
async def list_tools():
    """List available MCP tools."""
    try:
        tools = await chatbot_service.get_tools()
        return {
            "tools": [
                {
                    "name": name,
                    "description": tool.description,
                    "parameters": tool.inputSchema.get('properties', {}) if tool.inputSchema else {}
                }
                for name, tool in tools.items()
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    
    # Log startup information
    logger.info(f"Starting Zabbix Chatbot on port 9000")
    logger.info(f"MCP_URL: {MCP_URL}")
    logger.info(f"OLLAMA_HOST: {OLLAMA_HOST}")
    logger.info(f"OLLAMA_MODEL: {OLLAMA_MODEL}")
    
    try:
        uvicorn.run(app, host="0.0.0.0", port=9000, log_level="info")
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        raise

