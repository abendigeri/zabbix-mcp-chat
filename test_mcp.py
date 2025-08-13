#!/usr/bin/env python3
import asyncio
import aiohttp
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MCP_URL = os.getenv("MCP_URL", "http://zabbix-mcp:8000/mcp")

async def test_basic_http():
    """Test basic HTTP connectivity to MCP server."""
    try:
        timeout = aiohttp.ClientTimeout(total=10)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            # Test health endpoint
            health_url = MCP_URL.replace('/mcp', '/health')
            logger.info(f"Testing health endpoint: {health_url}")
            async with session.get(health_url) as response:
                logger.info(f"Health check status: {response.status}")
                if response.status == 200:
                    text = await response.text()
                    logger.info(f"Health response: {text}")
                
            # Test MCP endpoint
            logger.info(f"Testing MCP endpoint: {MCP_URL}")
            async with session.get(MCP_URL) as response:
                logger.info(f"MCP endpoint status: {response.status}")
                if response.status in [200, 405]:  # 405 is Method Not Allowed, which is expected for GET on MCP
                    logger.info("MCP endpoint is reachable")
                
    except Exception as e:
        logger.error(f"HTTP test failed: {e}")

async def test_mcp_protocol():
    """Test MCP protocol connection."""
    try:
        from mcp.client.streamable_http import streamablehttp_client
        
        logger.info("Testing MCP protocol connection...")
        
        # Suppress asyncio task group warnings
        old_level = logging.getLogger('asyncio').level
        logging.getLogger('asyncio').setLevel(logging.ERROR)
        
        try:
            async with streamablehttp_client(MCP_URL) as client:
                tools_response = await asyncio.wait_for(client.list_tools(), timeout=10.0)
                logger.info(f"MCP protocol test successful! Found {len(tools_response.tools)} tools:")
                for tool in tools_response.tools:
                    logger.info(f"  - {tool.name}: {tool.description}")
        finally:
            logging.getLogger('asyncio').setLevel(old_level)
            
    except Exception as e:
        logger.error(f"MCP protocol test failed: {e}")

async def main():
    logger.info(f"Testing MCP server at: {MCP_URL}")
    
    await test_basic_http()
    await test_mcp_protocol()

if __name__ == "__main__":
    asyncio.run(main())
