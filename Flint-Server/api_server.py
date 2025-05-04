import asyncio
import subprocess
import os
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import FileResponse
from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from mcp_use import MCPAgent, MCPClient

app = FastAPI()

load_dotenv()

class PromptRequest(BaseModel):
    prompt: str

# Change this to your real full path!
BLEND_FILENAME = "scene.blend"
EXPORT_FILENAME = "exported_model.usdz"
EXPORT_FOLDER = "YOUR_PREFERRED_PATH"
BLEND_PATH = os.path.join(EXPORT_FOLDER, BLEND_FILENAME)
EXPORT_PATH = os.path.join(EXPORT_FOLDER, EXPORT_FILENAME)

# Blender executable (change if needed)
BLENDER_PATH = "/Applications/Blender.app/Contents/MacOS/Blender"

@app.post("/run")
async def run_mcp_job(prompt_request: PromptRequest):
    prompt = prompt_request.prompt

    # Create MCPClient with Blender MCP configuration
    config = {"mcpServers": {"blender": {"command": "uvx", "args": ["blender-mcp"]}}}
    client = MCPClient.from_dict(config)

    # Create LLM
    llm = ChatAnthropic(model="claude-3-5-sonnet-20240620")

    # Create agent
    agent = MCPAgent(llm=llm, client=client, max_steps=30)

    result = None
    try:
        # Ensure exports directory exists
        os.makedirs(EXPORT_FOLDER, exist_ok=True)
        
        # Run the agent
        print("Starting MCP agent...")
        result = await agent.run(prompt + " When you're done, use the save_file command to save the project to " + BLEND_PATH, max_steps=30)
        
        print("Agent completed, now running export process...")
        
        # Run Blender export script using the saved .blend file
        process = subprocess.run([
            BLENDER_PATH,
            "--background",
            BLEND_PATH,  # Use the saved blend file
            "--python", "export_model.py",
            "--", EXPORT_PATH  # Pass the export path
        ], check=True, capture_output=True, text=True)
        
        print("Blender output:", process.stdout)
        
        if os.path.exists(EXPORT_PATH):
            file_url = f"http://YOUR_MAC_IP_ADDRESS:8000/download/{EXPORT_FILENAME}"
            return {"result": result, "model_url": file_url}
        else:
            return {"result": result, "error": "Model export failed. Check server logs."}
            
    except Exception as e:
        return {"error": str(e)}
    finally:
        # Make sure to close all sessions regardless of outcome
        if client.sessions:
            await client.close_all_sessions()

@app.get("/download/{filename}")
async def download_model(filename: str):
    file_path = os.path.join(EXPORT_FOLDER, filename)
    if not os.path.exists(file_path):
        return {"error": "File not found"}
    return FileResponse(path=file_path, filename=filename, media_type="application/octet-stream")