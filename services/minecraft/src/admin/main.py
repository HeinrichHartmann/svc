"""
Minecraft Server Admin Interface

FastAPI-based web UI for managing Minecraft worlds and server.
"""

import os
import shutil
from pathlib import Path
from typing import List, Dict, Any
import docker
from fastapi import FastAPI, HTTPException, Request, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates


# Configuration
MINECRAFT_CONTAINER = os.getenv("MINECRAFT_CONTAINER", "minecraft")
DATA_DIR = Path(os.getenv("DATA_DIR", "/data"))
WORLDS_DIR = Path(os.getenv("WORLDS_DIR", "/worlds"))
ACTIVE_WORLD_PATH = DATA_DIR / "world"

# Initialize FastAPI
app = FastAPI(title="Minecraft Admin", version="0.1.0")

# Templates
templates = Jinja2Templates(directory="templates")

# Docker client
docker_client = docker.from_env()


# Helper functions
def get_available_worlds() -> List[Dict[str, Any]]:
    """List all available worlds in the worlds directory."""
    worlds = []
    if not WORLDS_DIR.exists():
        return worlds

    for world_dir in sorted(WORLDS_DIR.iterdir()):
        if world_dir.is_dir() and not world_dir.name.startswith('.'):
            # Get world size
            size = sum(f.stat().st_size for f in world_dir.rglob('*') if f.is_file())
            size_mb = size / (1024 * 1024)

            worlds.append({
                "name": world_dir.name,
                "path": str(world_dir),
                "size_mb": round(size_mb, 2),
                "is_active": is_active_world(world_dir.name)
            })

    return worlds


def is_active_world(world_name: str) -> bool:
    """Check if a world is currently active."""
    if not ACTIVE_WORLD_PATH.exists():
        return False

    # Check if it's a symlink pointing to the world
    if ACTIVE_WORLD_PATH.is_symlink():
        target = ACTIVE_WORLD_PATH.resolve()
        return target.name == world_name

    # Otherwise check directory name match (after copy)
    # We'll store a marker file
    marker = ACTIVE_WORLD_PATH / ".world_source"
    if marker.exists():
        return marker.read_text().strip() == world_name

    return False


def get_current_world() -> str:
    """Get the name of the currently active world."""
    marker = ACTIVE_WORLD_PATH / ".world_source"
    if marker.exists():
        return marker.read_text().strip()
    return "world (default)"


def get_container_status() -> Dict[str, Any]:
    """Get Minecraft container status."""
    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        return {
            "name": container.name,
            "status": container.status,
            "running": container.status == "running",
            "id": container.short_id,
        }
    except docker.errors.NotFound:
        return {
            "name": MINECRAFT_CONTAINER,
            "status": "not_found",
            "running": False,
            "id": None,
        }
    except Exception as e:
        return {
            "name": MINECRAFT_CONTAINER,
            "status": f"error: {str(e)}",
            "running": False,
            "id": None,
        }


def get_container_logs(lines: int = 100) -> List[str]:
    """Get recent logs from Minecraft container."""
    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        logs = container.logs(tail=lines, timestamps=False).decode('utf-8')
        return logs.splitlines()
    except Exception as e:
        return [f"Error fetching logs: {str(e)}"]


def switch_world(world_name: str) -> bool:
    """Switch to a different world and restart the server."""
    world_source = WORLDS_DIR / world_name

    if not world_source.exists():
        raise HTTPException(status_code=404, detail=f"World '{world_name}' not found")

    try:
        # Stop the server
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        container.stop(timeout=30)

        # Remove old world
        if ACTIVE_WORLD_PATH.exists():
            shutil.rmtree(ACTIVE_WORLD_PATH)

        # Copy new world
        shutil.copytree(world_source, ACTIVE_WORLD_PATH)

        # Mark which world is active
        marker = ACTIVE_WORLD_PATH / ".world_source"
        marker.write_text(world_name)

        # Start the server
        container.start()

        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to switch world: {str(e)}")


# API Routes
@app.get("/api/status")
async def api_status():
    """Get server status."""
    return {
        "container": get_container_status(),
        "current_world": get_current_world(),
    }


@app.get("/api/worlds")
async def api_worlds():
    """List all available worlds."""
    return {
        "worlds": get_available_worlds(),
        "current": get_current_world(),
    }


@app.post("/api/world/switch/{world_name}")
async def api_switch_world(world_name: str):
    """Switch to a different world."""
    success = switch_world(world_name)
    return {
        "success": success,
        "world": world_name,
        "message": f"Switched to world '{world_name}' and restarted server"
    }


@app.post("/api/server/{action}")
async def api_server_action(action: str):
    """Control server (start/stop/restart)."""
    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)

        if action == "start":
            container.start()
            message = "Server started"
        elif action == "stop":
            container.stop(timeout=30)
            message = "Server stopped"
        elif action == "restart":
            container.restart(timeout=30)
            message = "Server restarted"
        else:
            raise HTTPException(status_code=400, detail=f"Unknown action: {action}")

        return {
            "success": True,
            "action": action,
            "message": message
        }
    except docker.errors.NotFound:
        raise HTTPException(status_code=404, detail="Container not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/logs")
async def api_logs(lines: int = 100):
    """Get server logs."""
    return {
        "logs": get_container_logs(lines),
        "lines": lines
    }


# Web UI Routes
@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Main admin interface."""
    return templates.TemplateResponse("index.html", {
        "request": request,
        "worlds": get_available_worlds(),
        "current_world": get_current_world(),
        "status": get_container_status(),
    })


@app.post("/api/world/upload")
async def upload_world(file: UploadFile):
    """Upload a world ZIP file."""
    import zipfile
    import tempfile

    if not file.filename.endswith('.zip'):
        raise HTTPException(status_code=400, detail="Only ZIP files are supported")

    try:
        # Create temp file for upload
        with tempfile.NamedTemporaryFile(delete=False, suffix='.zip') as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        # Extract to worlds directory
        world_name = file.filename.replace('.zip', '')
        extract_path = WORLDS_DIR / world_name

        if extract_path.exists():
            raise HTTPException(status_code=400, detail=f"World '{world_name}' already exists")

        with zipfile.ZipFile(tmp_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)

        # Clean up temp file
        Path(tmp_path).unlink()

        return {
            "success": True,
            "world": world_name,
            "message": f"World '{world_name}' uploaded successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@app.get("/console", response_class=HTMLResponse)
async def console(request: Request):
    """Console interface with authentication via Traefik."""
    # Auth is handled by Traefik middleware
    username = request.headers.get("X-Forwarded-User", "authenticated")
    return templates.TemplateResponse("console.html", {
        "request": request,
        "username": username,
        "status": get_container_status(),
    })


@app.post("/api/console/command")
async def execute_command(request: Request, command: dict):
    """Execute RCON command. Auth handled by Traefik."""
    cmd = command.get("command", "").strip()
    if not cmd:
        raise HTTPException(status_code=400, detail="Command cannot be empty")

    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        result = container.exec_run(f"rcon-cli {cmd}")
        return {
            "success": True,
            "output": result.output.decode('utf-8').strip(),
            "exit_code": result.exit_code,
            "command": cmd
        }
    except docker.errors.NotFound:
        raise HTTPException(status_code=404, detail="Container not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
