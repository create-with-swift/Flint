# Flint 3D Model Generation Server

FastAPI + MCP stack that turns text prompts into Blender scenes and exports USDZ files via `export_model.py`. 
## Overview

- Runs a FastAPI server (`api_server.py`) with `/run`, `/run-high`, `/download`, and `/health` endpoints.
- Uses MCP to drive Blender through the `blender-mcp` toolchain and exports via the bundled Python script.
- Keeps context usage in check with tool allowlists, step caps, and prompt truncation.
- Produces `.blend` and `.usdz` artifacts in `exports/` for downstream consumption.

## Highlights

- 🤖 **Claude Sonnet 4.5 integration** tuned for MCP workflows
- 🎨 **Automated Blender pipeline** that saves `.blend` files and exports USDZ
- 🔄 **Context-safe MCP bridge** (tool allowlists, token caps, step limits)

## Prerequisites

- macOS with Blender available at `/Applications/Blender.app/Contents/MacOS/Blender`
- Python 3.10+
- uv toolchain (needed for `uvx blender-mcp`): `brew install uv`
- Valid Anthropic API key stored in `.env` (`ANTHROPIC_API_KEY=...`)
- Recommended: create and activate the project virtual environment (`python -m venv .venv` then `source .venv/bin/activate`)

## Step-by-Step Setup

1. **Install Python 3.10+ and Blender** – Blender must be callable at `/Applications/Blender.app/Contents/MacOS/Blender` or you need to update `BLENDER_PATH` in `api_server.py`.
2. **Install uv (MCP helper)** – `brew install uv` so the `uvx blender-mcp` command in `api_server.py` works.
3. **Create a virtual environment** – `python -m venv .venv && source .venv/bin/activate` (recommended but optional).
4. **Install dependencies** – `pip install -r requirements.txt`.
5. **Create `.env`** in the project root with the secrets required by the scripts:
     ```bash
     cp config.env .env  # optional helper if you track defaults there
     ```
     Set at minimum:
     ```
     ANTHROPIC_API_KEY=sk-your-key
     BLENDER_PATH=/Applications/Blender.app/Contents/MacOS/Blender  # override if needed
     EXPORT_FOLDER=exports  # optional; defaults to project root
     ```
6. **Start the server** – `python start_server.py` (hot reload enabled).
7. **Check health** – `curl http://localhost:8000/health` should report `healthy` once Blender, the export folder, and the Claude API are accessible.

## API Endpoints

| Method | Path          | Description |
|--------|---------------|-------------|
| GET    | `/health`     | Reports Blender, Claude, and export-folder status |
| GET    | `/docs`       | FastAPI interactive docs |
| POST   | `/run`        | Standard-quality MCP generation (token-safe) |
| POST   | `/run-high`   | High-quality MCP generation (more steps/detail) |
| GET    | `/download/{filename}` | Fetch the latest USDZ export |

### Example Requests

Standard profile (balanced, ≤5 tool calls):

```bash
curl -X POST http://localhost:8000/run \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Create a sci-fi crate with glowing edges"}'
```

High-detail profile (≤8 tool calls, richer lighting/material cues):

```bash
curl -X POST http://localhost:8000/run-high \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Build a stylized medieval watchtower with torches and banners"}'
```

## Quality Profiles & Context Guards

| Profile   | Steps | LLM Tokens | Notes |
|-----------|-------|------------|-------|
| standard  | 5     | 1024       | Uses a minimal tool allowlist and aggressive prompt truncation for reliability |
| high      | 8     | 2048       | Adds richer geometry/material hints and allows the `set_texture` tool |

Both modes enforce:

- `toolContextSize="small"` to shrink tool schema payloads
- Explicit tool allowlists so unused MCP connectors never enter the prompt
- Constraint blocks injected into the LLM prompt (max tool calls, snippet size, mandatory `save_file`)
- Automatic `.blend` validation plus USDZ export via `export_model.py`

Switch to `/run-high` when you need more detail, then fall back to `/run` if you hit context limits.

## Configuration Notes

- `.env` is required; load order ensures anything defined there is available to both FastAPI and the export script.
- Populate `ANTHROPIC_API_KEY` plus any overrides (`BLENDER_PATH`, `EXPORT_FOLDER`, etc.).
- `config.env` can store shared defaults, but sensitive keys must still land in `.env` before running.
- Exports are written to `exports/scene.blend` and `exports/exported_model.usdz` unless you override `EXPORT_FOLDER`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `prompt is too long` errors | Use `/run`, shorten the prompt, or temporarily reduce the MCP allowlist |
| Blender path errors | Confirm the `BLENDER_PATH` constant matches your install or update it |
| Empty/invalid exports | Check server logs for Blender stderr, ensure `exports/` is writable |
| Claude 40x/429 responses | Wait and retry; the service already throttles tokens, but Anthropic quotas may still apply |

## Project Structure

```
Flint/
├── api_server.py      # FastAPI app + MCP orchestration
├── export_model.py    # Blender-side USDZ exporter
├── start_server.py    # Entrypoint with env bootstrap + uvicorn
├── requirements.txt   # Python dependencies
├── config.env         # Optional defaults you can copy into .env
├── package.json       # Node helpers (if any future tooling is added)
├── README.md          # This guide
└── exports/           # Generated blend/usdz assets
```
