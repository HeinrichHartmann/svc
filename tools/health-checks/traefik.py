#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""Traefik Health Check - Tests that Traefik is running and accessible"""

import subprocess
import sys
import urllib.request
import urllib.error
import ssl
import json


def check_container_running() -> bool:
    """Check if Traefik container is running"""
    try:
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
            check=True
        )
        if "traefik" in result.stdout:
            print("✓ Traefik container is running")
            return True
        else:
            print("✗ Traefik container is NOT running")
            return False
    except subprocess.CalledProcessError:
        print("✗ Could not check container status")
        return False


def check_dashboard() -> bool:
    """Check if Traefik dashboard is accessible"""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        urllib.request.urlopen(
            "https://traefik.lan.heinrichhartmann.net/api/overview",
            context=ctx,
            timeout=5
        )
        print("✓ Traefik dashboard is accessible")
        return True
    except (urllib.error.URLError, TimeoutError) as e:
        print(f"✗ Traefik dashboard is NOT accessible: {e}")
        return False


def check_routers() -> bool:
    """Check if Traefik has HTTP routers configured"""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        response = urllib.request.urlopen(
            "https://traefik.lan.heinrichhartmann.net/api/http/routers",
            context=ctx,
            timeout=5
        )
        routers = json.loads(response.read())
        router_count = len(routers)

        if router_count > 0:
            print(f"✓ Traefik has {router_count} HTTP routers configured")
            return True
        else:
            print("✗ Traefik has no HTTP routers")
            return False
    except Exception as e:
        print(f"✗ Could not check routers: {e}")
        return False


def check_ports() -> bool:
    """Check if Traefik ports are listening"""
    result = subprocess.run(
        ["ss", "-tlnp"],
        capture_output=True,
        text=True
    )

    all_passed = True
    for port in [80, 443]:
        if f":{port} " in result.stdout:
            print(f"✓ Port {port} is listening")
        else:
            print(f"✗ Port {port} is NOT listening")
            all_passed = False

    return all_passed


def main():
    print("=== Traefik Health Check ===")
    print()

    if not check_container_running():
        return 1

    all_passed = True
    all_passed &= check_dashboard()
    all_passed &= check_routers()
    all_passed &= check_ports()

    print()
    if all_passed:
        print("✓ All Traefik checks passed")
        return 0
    else:
        print("✗ Some Traefik checks failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
