#!/usr/bin/env python3
"""
Flint Server Startup Script
"""
import os
import sys

# Use virtual environment Python
VENV_PYTHON = "/Users/matteoaltobello/Documents/Flint/.venv/bin/python"
if sys.executable != VENV_PYTHON and os.path.exists(VENV_PYTHON):
    print("🔄 Using virtual environment Python...")
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Flint 3D Model Generation Server...")
    print("📡 Model: Claude Sonnet 4.5 (20250514)")
    print("🔗 Server will be available at: http://localhost:8000")
    print("📊 Health check: http://localhost:8000/health")
    print("📱 API docs: http://localhost:8000/docs")
    print("🔧 Protocol: MCP (Model Context Protocol)")
    print("⚡ Endpoints:")
    print("  • /run       – Standard MCP (token-safe)")  
    print("  • /run-high  – High-detail MCP (more steps)")
    print("🔧 Optimization: Context overflow protection active")
    print("")  
    
    uvicorn.run("api_server:app", host="0.0.0.0", port=8000, reload=True)
