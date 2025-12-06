#!/usr/bin/env bash
# Traefik Health Check
# Tests that Traefik is running and accessible

set -euo pipefail

failed=0

echo "=== Traefik Health Check ==="
echo

# Check container is running
if docker ps --format '{{.Names}}' | grep -q '^traefik$'; then
    echo "✓ Traefik container is running"
else
    echo "✗ Traefik container is NOT running"
    exit 1
fi

# Check dashboard is accessible
if curl -sk https://traefik.lan.heinrichhartmann.net/api/overview &>/dev/null; then
    echo "✓ Traefik dashboard is accessible"
else
    echo "✗ Traefik dashboard is NOT accessible"
    failed=1
fi

# Check if it's discovering services
router_count=$(curl -sk https://traefik.lan.heinrichhartmann.net/api/http/routers | grep -o '"name":"' | wc -l)
if [ "$router_count" -gt 0 ]; then
    echo "✓ Traefik has $router_count HTTP routers configured"
else
    echo "✗ Traefik has no HTTP routers"
    failed=1
fi

# Check ports
for port in 80 443; do
    if ss -tlnp | grep -q ":$port .*docker-proxy"; then
        echo "✓ Port $port is listening"
    else
        echo "✗ Port $port is NOT listening"
        failed=1
    fi
done

echo
if [ $failed -eq 0 ]; then
    echo "✓ All Traefik checks passed"
    exit 0
else
    echo "✗ Some Traefik checks failed"
    exit 1
fi
