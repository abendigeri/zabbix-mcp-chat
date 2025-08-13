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
MCP_ENABLED = os.getenv("MCP_ENABLED", "true").lower() in ("true", "1", "yes")

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
        self.mcp_available = False
    
    async def get_mcp_session(self) -> Optional[ClientSession]:
        """Get or create MCP session with error handling."""
        if not MCP_ENABLED:
            return None
            
        try:
            # Use the context manager properly
            client = streamablehttp_client(MCP_URL)
            session = await client.__aenter__()
            # Test connection by listing tools
            tools_response = await session.list_tools()
            logger.info(f"Connected to MCP server with {len(tools_response.tools)} tools")
            return session
        except Exception as e:
            logger.error(f"Failed to connect to MCP server: {e}")
            self.mcp_available = False
            return None
    
    async def get_tools(self, force_refresh: bool = False) -> Dict[str, mtypes.Tool]:
        """Get tools with caching."""
        if not MCP_ENABLED:
            return {}
            
        now = datetime.now()
        if (self.tools_cache is None or force_refresh or 
            (self.cache_timestamp and (now - self.cache_timestamp).seconds > 300)):
            
            session = await self.get_mcp_session()
            if session is None:
                logger.warning("MCP server not available, returning empty tools")
                return {}
            
            try:
                tools_resp = await session.list_tools()
                self.tools_cache = {t.name: t for t in tools_resp.tools}
                self.cache_timestamp = now
                self.mcp_available = True
                logger.info(f"Loaded {len(self.tools_cache)} tools from MCP server")
            except Exception as e:
                logger.error(f"Failed to list tools: {e}")
                return {}
        
        return self.tools_cache or {}
    
    def choose_tool_with_ollama(self, user_prompt: str, tools: Dict[str, mtypes.Tool]) -> Dict[str, Any]:
        """Use Ollama to choose appropriate tool."""
        try:
            # If no tools available, return no tool selection
            if not tools:
                return {"tool": None, "arguments": {}}
                
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
            
            # If no MCP tools available, provide a helpful response
            if not tools and MCP_ENABLED:
                return {
                    "choice": {"tool": None, "arguments": {}},
                    "result": {"text": "MCP server is not available. Please check the connection to the Zabbix MCP server."},
                    "error": "mcp_unavailable",
                    "timestamp": datetime.now().isoformat()
                }
            elif not tools and not MCP_ENABLED:
                return {
                    "choice": {"tool": None, "arguments": {}},
                    "result": {"text": "MCP functionality is disabled. Only basic chat functionality is available."},
                    "error": "mcp_disabled",
                    "timestamp": datetime.now().isoformat()
                }
            
            choice = self.choose_tool_with_ollama(user_prompt, tools)
            
            tool_name = choice.get("tool")
            args = choice.get("arguments", {})
            
            if not tool_name or tool_name not in tools:
                return {
                    "choice": choice,
                    "result": {"text": f"No suitable tool found for your query. Available tools: {', '.join(tools.keys()) if tools else 'None'}"},
                    "error": "no_tool_selected",
                    "available_tools": list(tools.keys()),
                    "timestamp": datetime.now().isoformat()
                }
            
            # Get fresh session for tool execution
            session = await self.get_mcp_session()
            if session is None:
                return {
                    "choice": choice,
                    "result": {"text": "Failed to connect to MCP server for tool execution."},
                    "error": "mcp_connection_failed",
                    "timestamp": datetime.now().isoformat()
                }
            
            try:
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
                logger.error(f"Tool execution failed: {e}")
                return {
                    "choice": choice,
                    "result": {"text": f"Tool execution failed: {str(e)}"},
                    "error": "tool_execution_failed",
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            return {
                "choice": None,
                "result": {"text": f"Query processing failed: {str(e)}"},
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
    logger.info(f"MCP enabled: {MCP_ENABLED}")
    logger.info(f"MCP URL: {MCP_URL}")
    
    if MCP_ENABLED:
        try:
            # Test MCP connection
            tools = await chatbot_service.get_tools()
            if tools:
                logger.info(f"Successfully connected to MCP server with {len(tools)} tools")
                chatbot_service.mcp_available = True
            else:
                logger.warning("MCP server connection failed, continuing without MCP functionality")
        except Exception as e:
            logger.warning(f"MCP server not available: {e}. Continuing without MCP functionality")
    else:
        logger.info("MCP functionality disabled")
    
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
    health_status = {
        "status": "healthy",
        "mcp_enabled": MCP_ENABLED,
        "timestamp": datetime.now().isoformat()
    }
    
    if MCP_ENABLED:
        try:
            tools = await chatbot_service.get_tools()
            health_status.update({
                "mcp_connection": "ok" if tools else "unavailable",
                "tools_count": len(tools)
            })
        except Exception as e:
            health_status.update({
                "mcp_connection": "error",
                "mcp_error": str(e),
                "tools_count": 0
            })
    else:
        health_status.update({
            "mcp_connection": "disabled",
            "tools_count": 0
        })
    
    return health_status

@app.get("/tools")
async def list_tools():
    """List available MCP tools."""
    if not MCP_ENABLED:
        return {
            "mcp_enabled": False,
            "tools": [],
            "message": "MCP functionality is disabled"
        }
    
    try:
        tools = await chatbot_service.get_tools()
        return {
            "mcp_enabled": True,
            "tools": [
                {
                    "name": name,
                    "description": tool.description,
                    "parameters": tool.inputSchema.get('properties', {}) if tool.inputSchema else {}
                }
                for name, tool in tools.items()
            ],
            "tools_count": len(tools)
        }
    except Exception as e:
        return {
            "mcp_enabled": True,
            "tools": [],
            "error": str(e),
            "message": "Failed to retrieve tools from MCP server"
        }

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

