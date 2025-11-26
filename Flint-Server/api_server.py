import asyncio
import subprocess
import os
import time
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import FileResponse
from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from mcp_use import MCPAgent, MCPClient

app = FastAPI()

# Load environment variables from .env file
load_dotenv(override=True)

class PromptRequest(BaseModel):
    prompt: str

# Paths and filenames
BLEND_FILENAME = "scene.blend"
EXPORT_FILENAME = "exported_model.usdz"
EXPORT_FOLDER = ""
BLEND_PATH = os.path.join(EXPORT_FOLDER, BLEND_FILENAME)
EXPORT_PATH = os.path.join(EXPORT_FOLDER, EXPORT_FILENAME)
BLENDER_PATH = "/Applications/Blender.app/Contents/MacOS/Blender"
EXPORT_SCRIPT_PATH = os.path.join(os.getcwd(), "export_model.py") 

# MCP context safety controls
MCP_ALLOWED_TOOLS = [
    "execute_blender_code",
    "get_scene_info",
    "get_object_info",
    "get_viewport_screenshot",
    "save_file",
    "asset_creation_strategy"
]
HIGH_QUALITY_TOOL_ALLOWLIST = MCP_ALLOWED_TOOLS + ["set_texture"]

SYSTEM_INSTRUCTIONS = (
    "You are a Blender MCP operator. Use only approved tools, keep tool calls concise, "
    "avoid repeating large code blocks, and always call save_file to persist the scene "
    "before finishing."
)

QUALITY_PROFILES = {
    "standard": {
        "max_steps": 5,
        "max_tokens": 1024,
        "temperature": 0.2,
        "max_prompt_chars": 240,
        "blend_timeout": 60,
        "export_timeout": 90,
        "tool_allowlist": MCP_ALLOWED_TOOLS,
        "system_hint": "Operate in ultra-concise mode to minimize token usage.",
        "detail_hint": None,
    },
    "high": {
        "max_steps": 8,
        "max_tokens": 2048,
        "temperature": 0.35,
        "max_prompt_chars": 400,
        "blend_timeout": 90,
        "export_timeout": 120,
        "tool_allowlist": HIGH_QUALITY_TOOL_ALLOWLIST,
        "system_hint": "Increase geometric richness while staying within the step limit.",
        "detail_hint": "Layer in secondary shapes, balanced lighting, and subtle material variation.",
    },
}


async def run_generation(prompt: str, profile_name: str):
    """Execute the MCP workflow using the requested quality profile."""
    if profile_name not in QUALITY_PROFILES:
        return {"error": f"Unknown profile '{profile_name}'"}

    profile = QUALITY_PROFILES[profile_name]

    config = {
        "mcpServers": {
            "blender": {
                "command": "uvx",
                "args": ["blender-mcp"],
                "toolContextSize": "small",
                "toolAllowList": profile.get("tool_allowlist", MCP_ALLOWED_TOOLS),
            }
        }
    }
    client = MCPClient.from_dict(config)

    try:
        llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            max_tokens=profile["max_tokens"],
            temperature=profile["temperature"],
            system=f"{SYSTEM_INSTRUCTIONS} {profile.get('system_hint', '')}".strip()
        )
    except Exception as e:
        return {"error": f"Failed to initialize Claude: {str(e)}"}

    agent = MCPAgent(
        llm=llm,
        client=client,
        use_server_manager=True,
        max_steps=profile["max_steps"],
    )

    result = None
    try:
        os.makedirs(EXPORT_FOLDER, exist_ok=True)

        base_prompt = (prompt or "Create a simple scene").strip()
        base_prompt = base_prompt[: profile["max_prompt_chars"]]
        constraints = [
            f"Use at most {profile['max_steps']} tool calls.",
            "Prefer code snippets under ~200 tokens.",
            f"Finish by calling save_file to {BLEND_PATH}.",
        ]
        if profile.get("detail_hint"):
            constraints.append(f"Detail hint: {profile['detail_hint']}")

        enhanced_prompt = f"{base_prompt}\n\nConstraints:\n" + "\n".join(
            f"- {line}" for line in constraints
        )

        print(
            f"Starting MCP agent (profile={profile_name}, max_steps={profile['max_steps']})..."
        )
        result = await agent.run(enhanced_prompt)

        if result:
            print(f"✅ Agent: {str(result)[:50]}...")
        else:
            print("⚠️ Agent: No result")

        print("Waiting for .blend file to be saved...")
        await wait_for_file(BLEND_PATH, timeout=profile["blend_timeout"])

        if not os.path.exists(BLEND_PATH):
            return {"error": "Blend file was not created"}

        if os.path.getsize(BLEND_PATH) < 1024:
            return {"error": "Blend file appears to be invalid (too small)"}

        print("Blend file detected. Now running export process...")

        process = subprocess.run(
            [
                BLENDER_PATH,
                "--background",
                BLEND_PATH,
                "--python",
                EXPORT_SCRIPT_PATH,
                "--",
                EXPORT_PATH,
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=profile["export_timeout"],
        )

        print("✅ Export completed")
        if process.stderr and len(process.stderr) > 100:
            print(f"Blender warnings: {process.stderr[:100]}...")

        if os.path.exists(EXPORT_PATH) and os.path.getsize(EXPORT_PATH) > 0:
            file_url = f"/download/{EXPORT_FILENAME}"
            return {
                "success": True,
                "model_url": file_url,
                "model": "Claude Sonnet 4.5",
                "protocol": f"MCP {profile_name.title()} ({profile['max_steps']} steps)",
                "size": os.path.getsize(EXPORT_PATH),
            }
        else:
            return {"error": "Export failed"}

    except subprocess.TimeoutExpired:
        return {"error": "Blender export timed out"}
    except Exception as e:
        return {"error": f"An error occurred: {str(e)}"}
    finally:
        try:
            if client and client.sessions:
                await client.close_all_sessions()
        except Exception as e:
            print(f"Warning: Failed to close MCP sessions: {e}")

async def wait_for_file(file_path, timeout=30):
    """Wait for a file to exist for up to `timeout` seconds."""
    start_time = time.time()
    while not os.path.exists(file_path):
        if time.time() - start_time > timeout:
            raise TimeoutError(f"Timed out waiting for {file_path} to be created.")
        await asyncio.sleep(1)

@app.post("/run")
async def run_mcp_job(prompt_request: PromptRequest):
    if not prompt_request.prompt or not prompt_request.prompt.strip():
        return {"error": "Prompt cannot be empty"}

    return await run_generation(prompt_request.prompt, "standard")


@app.post("/run-high")
async def run_high_quality(prompt_request: PromptRequest):
    if not prompt_request.prompt or not prompt_request.prompt.strip():
        return {"error": "Prompt cannot be empty"}

    return await run_generation(prompt_request.prompt, "high")


@app.get("/download/{filename}")
async def download_model(filename: str):
    # Security: only allow downloading the export file
    if filename != EXPORT_FILENAME:
        return {"error": "File not allowed"}
    
    file_path = os.path.join(EXPORT_FOLDER, filename)
    if not os.path.exists(file_path):
        return {"error": "File not found"}
    
    return FileResponse(path=file_path, filename=filename, media_type="application/octet-stream")



@app.get("/health")
async def health_check():
    """Health check endpoint to verify server and dependencies."""
    try:
        # Check if Blender exists
        blender_ok = os.path.exists(BLENDER_PATH)
        
        # Check if export folder is writable
        export_folder_ok = os.access(EXPORT_FOLDER, os.W_OK) if os.path.exists(EXPORT_FOLDER) else True
        
        # Check Claude API (simple test)
        claude_ok = False
        try:
            from langchain_anthropic import ChatAnthropic
            llm = ChatAnthropic(model="claude-sonnet-4-20250514", max_tokens=10)
            test_response = llm.invoke("Hi")
            claude_ok = True
        except Exception:
            claude_ok = False
        
        return {
            "status": "healthy" if all([blender_ok, export_folder_ok, claude_ok]) else "degraded",
            "components": {
                "blender": blender_ok,
                "export_folder": export_folder_ok,
                "claude_api": claude_ok
            },
            "model": "claude-sonnet-4-20250514"
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
