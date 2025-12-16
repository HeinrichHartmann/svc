# Upgrade Minecraft Server

## Task
Upgrade the Minecraft server to the latest version.

## Steps

1. **Check latest version**
   - Search for "Minecraft Java Edition latest version" to find current release
   - Compare with version in docker-compose.yaml

2. **Update version in docker-compose.yaml**
   - File: `/svc/services/minecraft/docker-compose.yaml`
   - Update the `VERSION` environment variable to the new version
   - Example: `VERSION: "1.21.11"`

3. **Restart the server**
   ```bash
   cd /svc/services/minecraft
   docker compose pull
   docker compose up -d
   ```

4. **Verify startup**
   ```bash
   docker logs minecraft --tail 30
   ```
   - Look for "Done" message indicating successful startup
   - Verify version number in logs matches expected version

## Notes

- The server uses `itzg/minecraft-server:latest` Docker image
- World data is stored in `/share/hhartmann/var/minecraft`
- Server runs in offline mode (ONLINE_MODE=false)
- Default port: 25565
