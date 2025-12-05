# Minecraft Server Service
# Note: Minecraft uses TCP port 25565, not HTTP, so no URL test available
# Test via: mc-status localhost:25565 or check docker logs

COMPOSEFILE=docker-compose.yaml

start:
	@echo "Creating /svc/var/minecraft/data directory if needed..."
	@mkdir -p /svc/var/minecraft/data
	docker compose -f $(COMPOSEFILE) --ansi never up -d

stop:
	docker compose -f $(COMPOSEFILE) --ansi never down

restart: stop start

logs:
	docker compose -f $(COMPOSEFILE) logs -f

test:
	@echo "Checking Minecraft server status..."
	@docker ps | grep minecraft | grep -q "Up" && echo "✓ Minecraft container running" || echo "✗ Minecraft container not running"
	@docker exec minecraft mc-health 2>/dev/null && echo "✓ Minecraft server responding" || echo "✗ Minecraft server not responding (may still be starting)"

update:
	docker compose -f $(COMPOSEFILE) pull -q

# Additional helper commands
console:
	@echo "Attaching to Minecraft console (CTRL+P then CTRL+Q to detach without stopping)..."
	docker attach minecraft

status:
	@docker exec minecraft mc-status localhost 2>/dev/null || echo "Server not ready yet"
