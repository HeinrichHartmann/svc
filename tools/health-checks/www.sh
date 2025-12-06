#!/usr/bin/env bash
# WWW Service Health Check
# Tests that the www nginx service is accessible

set -euo pipefail

failed=0

echo "=== WWW Service Health Check ==="
echo

# Check container is running
if docker ps --format '{{.Names}}' | grep -q 'www-www-1'; then
    echo "✓ WWW container is running"
else
    echo "✗ WWW container is NOT running"
    exit 1
fi

# Check via localhost/Traefik
response=$(curl -sk -H "Host: www.heinrichhartmann.net" https://localhost/ 2>&1)
if echo "$response" | grep -q "Hello from WWW"; then
    echo "✓ WWW service responds via Traefik (localhost)"
else
    echo "✗ WWW service does NOT respond correctly via Traefik"
    echo "  Response: $response"
    failed=1
fi

# Check via Tailscale IP
response=$(curl -sk -H "Host: www.heinrichhartmann.net" https://100.75.70.47/ 2>&1)
if echo "$response" | grep -q "Hello from WWW"; then
    echo "✓ WWW service responds via Tailscale IP"
else
    echo "✗ WWW service does NOT respond via Tailscale IP"
    failed=1
fi

echo
if [ $failed -eq 0 ]; then
    echo "✓ All WWW checks passed"
    exit 0
else
    echo "✗ Some WWW checks failed"
    exit 1
fi
