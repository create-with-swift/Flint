# Flint - Blender MCP API Server for macOS/iOS

Flint is a FastAPI server that uses Blender MCP addon from -----add mention to the original repo----- (Multimodal Capability Protocol) with Claude to generate and export 3D models based on text prompts. This guide is specifically for macOS and iOS environments.

## Overview

This project provides an API service that:
1. Takes text prompts describing 3D models
2. Uses Claude and MCP to generate Blender scenes (-----mention)
3. Exports the resulting 3D models as USDZ files
4. Provides an endpoint to download the exported models

## Prerequisites

- macOS operating system
- [Homebrew](https://brew.sh/) package manager
- Python 3.11+
- Blender (latest stable version recommended)
- pip (Python package manager)
- Blender MCP addon from [blender-mcp repository](https://github.com/ahujasid/blender-mcp)

## Initial Setup

### 1. Install Blender MCP Addon

Before proceeding with the API server installation, you need to set up the Blender MCP addon:

1. Clone or download the Blender MCP repository:
   ```bash
   git clone https://github.com/ahujasid/blender-mcp.git
   ```

2. Copy at least the `addon.py` file from the repository to your Blender addons directory.

3. Enable the addon in Blender:
   - Open Blender
   - Go to Edit > Preferences > Add-ons
   - Find and enable the MCP addon
   - Save preferences

## Installation

After completing the initial setup with the Blender MCP addon, follow these steps to install the API server:


### 2. Clone the repository
Clone the repo and move to the Flint Server folder

```bash
cd Flint Server
```



### 3. Create and activate a virtual environment

```bash
python3 -m venv venv

source .venv/bin/activate
```

### 4. Install required Python packages

```bash
pip install fastapi uvicorn python-dotenv pydantic langchain langchain-anthropic mcp-use fastembed
```

### 5. Install MCP dependencies

```bash
# Install UVX CLI tool
brew install uv


### 6. Add your own Claude API Key

Create an  `.env` file in the project root add your own API Key:

```
ANTHROPIC_API_KEY=your_anthropic_api_key
```

### 7. Configure file paths

Edit `api_server.py` to update the following paths according to your macOS system:

```python
# Change these to your real full paths!
EXPORT_FOLDER = "/path/to/your/exports/folder"
BLENDER_PATH = "/Applications/Blender.app/Contents/MacOS/Blender"
```

Make sure the BLENDER_PATH points to your Blender installation on macOS, which is typically located at `/Applications/Blender.app/Contents/MacOS/Blender`.

Add your mac ip address in this line:

```bash
file_url = f"<Your-ip-address>:8000/download/{EXPORT_FILENAME}"
```

Edit `esport_model.py` to update the following paths according to your macOS system:
output_path = "/Users/../../exported_model.usdz"


## Usage

### Start the server

```bash
uvicorn api_server:app --reload --host 0.0.0.0 --port 8000
```

### Generate a 3D model

Send a POST request to the `/run` endpoint:

```bash
curl -X POST "http://localhost:8000/run" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Create a low-poly tree with green leaves and a brown trunk"}'
```

The response will include the result and a URL to download the exported model.

### Download the model

Use the returned URL or access directly:

```
http://localhost:8000/download/exported_model.usdz
```
If it does not work substitute localhost with your personal Mac IP address

## API Endpoints

### POST /run

Generates a 3D model based on a text prompt.

**Request Body:**
```json
{
  "prompt": "Description of the 3D model to create"
}
```

**Response:**
```json
{
  "result": "MCP agent execution result",
  "model_url": "URL to download the generated model"
}
```

### GET /download/{filename}

Downloads a generated model file.

## Troubleshooting

### Common Issues

1. **Blender not found**: Ensure the `BLENDER_PATH` is correctly set to your Blender executable location on macOS.

2. **MCP errors**: Make sure you have properly installed the Blender MCP addon from the GitHub repository and enabled it in Blender preferences.

3. **File permission issues**: Ensure the export directory is writable by the user running the server.


### Logs

Check the server console output for detailed logs and error messages.

## License

[MIT License](LICENSE)

## Acknowledgements

- This project uses [Anthropic's Claude](https://www.anthropic.com/) for natural language processing
- [Multimodal Capability Protocol (MCP)](https://github.com/anthropics/anthropic-multimodal-capability-protocol) for Blender integration
- [FastAPI](https://fastapi.tiangolo.com/) for the web server framework

