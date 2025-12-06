#!/usr/bin/env bash
# Samba Health Check
# Tests that Samba is running and shares are accessible

set -euo pipefail

# Check if samba services are running
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo "✓ $service is running"
        return 0
    else
        echo "✗ $service is NOT running"
        return 1
    fi
}

# Check if shares are accessible
check_shares() {
    if smbclient -L localhost -N &>/dev/null; then
        echo "✓ Samba shares are accessible"

        # List shares
        echo "  Available shares:"
        smbclient -L localhost -N 2>/dev/null | grep "Disk" | awk '{print "    - " $1}'
        return 0
    else
        echo "✗ Cannot list Samba shares"
        return 1
    fi
}

# Check if ports are listening
check_ports() {
    local failed=0
    for port in 139 445; do
        if ss -tlnp | grep -q ":$port "; then
            echo "✓ Port $port is listening"
        else
            echo "✗ Port $port is NOT listening"
            failed=1
        fi
    done
    return $failed
}

echo "=== Samba Health Check ==="
echo

failed=0

check_service "samba-smbd.service" || failed=1
check_service "samba-nmbd.service" || failed=1
check_service "samba-winbindd.service" || failed=1

echo
check_ports || failed=1

echo
check_shares || failed=1

echo
if [ $failed -eq 0 ]; then
    echo "✓ All Samba checks passed"
    exit 0
else
    echo "✗ Some Samba checks failed"
    exit 1
fi
