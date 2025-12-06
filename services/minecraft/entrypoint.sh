#!/bin/bash
set -e

echo "=== Minecraft Server Startup ==="

# Verify active world symlink exists
if [ ! -L "/data/active" ]; then
    echo "ERROR: /data/active symlink not found!"
    echo "Please create symlink to a world: ln -s worlds/WORLDNAME /data/active"
    exit 1
fi

# Check if symlink points to valid world
if [ ! -d "/data/active" ]; then
    echo "ERROR: /data/active points to non-existent world!"
    echo "Current target: $(readlink /data/active)"
    exit 1
fi

echo "Active world: $(readlink /data/active)"
echo "World exists: ✓"

# Run the original Minecraft server entrypoint
exec /start
