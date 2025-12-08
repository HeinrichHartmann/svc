"""
Minecraft Server Admin Interface

FastAPI-based web UI for managing Minecraft worlds and server.
"""

import os
import shutil
import time
from pathlib import Path
from typing import List, Dict, Any, Optional
import docker
from fastapi import FastAPI, HTTPException, Request, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates


# Configuration
MINECRAFT_CONTAINER = os.getenv("MINECRAFT_CONTAINER", "minecraft")
DATA_DIR = Path(os.getenv("DATA_DIR", "/data"))
WORLDS_DIR = DATA_DIR / "worlds"  # Worlds are now in /data/worlds
ACTIVE_SYMLINK = DATA_DIR / "active"  # Symlink to active world

# Initialize FastAPI
app = FastAPI(title="Minecraft Admin", version="0.1.0")

# Templates
templates = Jinja2Templates(directory="templates")

# Docker client
docker_client = docker.from_env()

# Status cache (to avoid hammering RCON)
_status_cache: Optional[Dict[str, Any]] = None
_status_cache_time: float = 0
STATUS_CACHE_TTL = 5  # seconds


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
    if not ACTIVE_SYMLINK.exists():
        return False

    # Check if symlink points to this world
    if ACTIVE_SYMLINK.is_symlink():
        target = os.readlink(ACTIVE_SYMLINK)
        # target is relative: "worlds/WorldName"
        return target == f"worlds/{world_name}"

    return False


def get_current_world() -> str:
    """Get the name of the currently active world."""
    if ACTIVE_SYMLINK.is_symlink():
        target = os.readlink(ACTIVE_SYMLINK)
        # target is "worlds/WorldName"
        if "/" in target:
            return target.split("/")[-1]
        return target
    return "none"


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


def get_online_players() -> tuple[List[str], Optional[str]]:
    """Get list of currently online players. Returns (players, error)."""
    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)

        # Check if container is actually running
        if container.status != "running":
            return ([], "Server not running")

        result = container.exec_run("rcon-cli list", demux=False)
        output = result.output.decode('utf-8').strip()

        # Check for RCON connection errors
        if "Failed to connect" in output or "connection refused" in output:
            return ([], "RCON not ready (server starting up)")

        # Parse output like "There are 3 of a max of 20 players online: Player1, Player2, Player3"
        if ":" in output:
            player_part = output.split(":", 1)[1].strip()
            if player_part:
                return ([p.strip() for p in player_part.split(",")], None)

        return ([], None)
    except docker.errors.NotFound:
        return ([], "Container not found")
    except Exception as e:
        return ([], f"Error: {str(e)}")


def get_player_gamemode(player: str) -> Optional[str]:
    """Get the game mode of a player. Returns None if unable to determine."""
    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        if container.status != "running":
            return None

        # Use data get to query the player's game mode
        result = container.exec_run(f"rcon-cli 'data get entity {player} playerGameType'", demux=False)
        output = result.output.decode('utf-8').strip()

        # Parse output like "Player has the following entity data: 0"
        # 0=survival, 1=creative, 2=adventure, 3=spectator
        if "has the following entity data:" in output:
            mode_num = output.split(":")[-1].strip()
            mode_map = {"0": "survival", "1": "creative", "2": "adventure", "3": "spectator"}
            return mode_map.get(mode_num, "unknown")

        return None
    except Exception:
        return None


def get_players_with_gamemodes() -> tuple[List[Dict[str, Any]], Optional[str]]:
    """Get list of online players with their game modes."""
    players, error = get_online_players()
    if error:
        return ([], error)

    players_data = []
    for player in players:
        gamemode = get_player_gamemode(player)
        players_data.append({
            "name": player,
            "gamemode": gamemode or "unknown"
        })

    return (players_data, None)


def set_player_gamemode(player: str, gamemode: str) -> tuple[bool, str]:
    """Set a player's game mode. Returns (success, message)."""
    valid_modes = ["survival", "creative", "adventure", "spectator"]
    if gamemode not in valid_modes:
        return (False, f"Invalid game mode. Must be one of: {', '.join(valid_modes)}")

    try:
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        if container.status != "running":
            return (False, "Server not running")

        result = container.exec_run(f"rcon-cli 'gamemode {gamemode} {player}'", demux=False)
        output = result.output.decode('utf-8').strip()

        # Success looks like "Set Player's game mode to Survival Mode"
        if "game mode to" in output.lower() or "Set" in output:
            return (True, output)

        return (False, output or "Unknown error")
    except docker.errors.NotFound:
        return (False, "Container not found")
    except Exception as e:
        return (False, str(e))


def switch_world(world_name: str) -> bool:
    """Switch to a different world and restart the server."""
    world_source = WORLDS_DIR / world_name

    if not world_source.exists():
        raise HTTPException(status_code=404, detail=f"World '{world_name}' not found")

    try:
        # Stop the server
        container = docker_client.containers.get(MINECRAFT_CONTAINER)
        container.stop(timeout=30)

        # Update symlink to point to new world
        symlink_target = f"worlds/{world_name}"

        # Remove old symlink if exists
        if ACTIVE_SYMLINK.exists() or ACTIVE_SYMLINK.is_symlink():
            ACTIVE_SYMLINK.unlink()

        # Create new symlink
        ACTIVE_SYMLINK.symlink_to(symlink_target)

        # Start the server
        container.start()

        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to switch world: {str(e)}")


# API Routes
@app.get("/api/status")
async def api_status():
    """Get server status with caching to avoid hammering RCON."""
    global _status_cache, _status_cache_time

    now = time.time()

    # Return cached status if still fresh
    if _status_cache and (now - _status_cache_time) < STATUS_CACHE_TTL:
        return _status_cache

    # Fetch fresh status
    container = get_container_status()
    players, players_error = get_online_players()

    status = {
        "container": container,
        "current_world": get_current_world(),
        "online_players": players,
        "players_error": players_error,
        "cached_at": int(now),
    }

    # Update cache
    _status_cache = status
    _status_cache_time = now

    return status


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


@app.get("/api/players")
async def api_players():
    """Get online players with their game modes."""
    players, error = get_players_with_gamemodes()
    return {
        "players": players,
        "error": error
    }


@app.post("/api/player/{player}/gamemode/{gamemode}")
async def api_set_gamemode(player: str, gamemode: str):
    """Set a player's game mode."""
    success, message = set_player_gamemode(player, gamemode)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {
        "success": True,
        "player": player,
        "gamemode": gamemode,
        "message": message
    }


# Web UI Routes
@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Main admin interface."""
    players, players_error = get_online_players()
    return templates.TemplateResponse("index.html", {
        "request": request,
        "worlds": get_available_worlds(),
        "current_world": get_current_world(),
        "status": get_container_status(),
        "online_players": players,
        "players_error": players_error,
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
