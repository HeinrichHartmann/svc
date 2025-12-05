#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""Minecraft Health Check - Tests that Minecraft server and admin are running"""

import subprocess
import sys
import urllib.request
import urllib.error
import ssl
import json


def check_container_running(name: str) -> bool:
    """Check if a container is running"""
    try:
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
            check=True
        )
        if name in result.stdout:
            print(f"✓ {name} container is running")
            return True
        else:
            print(f"✗ {name} container is NOT running")
            return False
    except subprocess.CalledProcessError:
        print(f"✗ Could not check {name} container status")
        return False


def check_minecraft_port() -> bool:
    """Check if Minecraft server port 25565 is listening"""
    result = subprocess.run(
        ["ss", "-tlnp"],
        capture_output=True,
        text=True
    )

    if ":25565 " in result.stdout:
        print("✓ Minecraft server port 25565 is listening")
        return True
    else:
        print("✗ Minecraft server port 25565 is NOT listening")
        return False


def check_admin_web() -> bool:
    """Check if admin web interface is accessible"""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        response = urllib.request.urlopen(
            "https://minecraft.lan/health",
            context=ctx,
            timeout=5
        )
        data = json.loads(response.read())

        if data.get("status") == "healthy":
            print("✓ Admin web interface is healthy")
            return True
        else:
            print("✗ Admin web interface returned unhealthy status")
            return False
    except (urllib.error.URLError, TimeoutError) as e:
        print(f"✗ Admin web interface is NOT accessible: {e}")
        return False


def check_admin_api() -> bool:
    """Check if admin API is accessible"""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        response = urllib.request.urlopen(
            "https://minecraft.lan/api/status",
            context=ctx,
            timeout=5
        )
        data = json.loads(response.read())

        if "container" in data:
            container_status = data["container"].get("status")
            current_world = data.get("current_world", "unknown")
            print(f"✓ Admin API accessible - Server: {container_status}, World: {current_world}")
            return True
        else:
            print("✗ Admin API returned unexpected format")
            return False
    except Exception as e:
        print(f"✗ Admin API is NOT accessible: {e}")
        return False


def check_minecraft_health() -> bool:
    """Check Minecraft server health via docker exec"""
    try:
        result = subprocess.run(
            ["docker", "exec", "minecraft", "mc-health"],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            print("✓ Minecraft server health check passed")
            return True
        else:
            print(f"✗ Minecraft server health check failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("✗ Minecraft server health check timed out")
        return False
    except Exception as e:
        print(f"✗ Could not run Minecraft health check: {e}")
        return False


def main():
    print("=== Minecraft Health Check ===")
    print()

    all_passed = True

    # Check containers
    all_passed &= check_container_running("minecraft")
    all_passed &= check_container_running("minecraft-admin")

    # Check Minecraft server
    all_passed &= check_minecraft_port()
    all_passed &= check_minecraft_health()

    # Check admin interface
    all_passed &= check_admin_web()
    all_passed &= check_admin_api()

    print()
    if all_passed:
        print("✓ All Minecraft checks passed")
        return 0
    else:
        print("✗ Some Minecraft checks failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
