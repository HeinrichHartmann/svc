#!/usr/bin/env bash
#
# ZFS Auto-Snapshot Health Check
#
# Validates that ZFS auto-snapshot is working correctly:
# - Checks for filesystems with auto-snapshot enabled
# - Verifies recent snapshots exist
# - Validates systemd timers are active
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

echo "=== ZFS Auto-Snapshot Health Check ==="
echo

# Check 1: Find filesystems with auto-snapshot enabled
echo "Checking for filesystems with auto-snapshot enabled..."
AUTOSNAP_FS=$(zfs get -H -o name,value com.sun:auto-snapshot | grep -w "true" | awk '{print $1}' || true)

if [ -z "$AUTOSNAP_FS" ]; then
    log_warn "No filesystems have auto-snapshot enabled"
else
    log_ok "Found $(echo "$AUTOSNAP_FS" | wc -l) filesystem(s) with auto-snapshot enabled"
    echo "$AUTOSNAP_FS" | while read -r fs; do
        echo "  - $fs"
    done
fi
echo

# Check 2: Verify systemd timers are active
echo "Checking systemd timers..."
for interval in daily weekly monthly; do
    timer="zfs-auto-snapshot-${interval}.timer"
    if systemctl is-active --quiet "$timer" 2>/dev/null; then
        # Get next run time
        next_run=$(systemctl status "$timer" 2>/dev/null | grep "Trigger:" | awk -F': ' '{print $2}' || echo "unknown")
        log_ok "$timer is active (next: $next_run)"
    else
        log_error "$timer is not active"
    fi
done
echo

# Check 3: Verify recent snapshots exist
echo "Checking for recent snapshots..."
NOW=$(date +%s)
ONE_DAY=$((24 * 3600))
TWO_DAYS=$((2 * ONE_DAY))
ONE_WEEK=$((7 * ONE_DAY))
THIRTY_DAYS=$((30 * ONE_DAY))

if [ -n "$AUTOSNAP_FS" ]; then
    echo "$AUTOSNAP_FS" | while read -r fs; do
        echo "  Filesystem: $fs"

        # Check for daily snapshots
        daily_snaps=$(zfs list -H -t snapshot -o name -s creation "$fs" 2>/dev/null | grep "zfs-auto-snap_daily" | tail -5 || true)
        if [ -z "$daily_snaps" ]; then
            log_warn "No daily snapshots found for $fs"
        else
            latest_daily=$(echo "$daily_snaps" | tail -1)
            # Extract timestamp from snapshot name (format: zfs-auto-snap_daily-YYYY-MM-DD-HHhMMU)
            snap_date=$(echo "$latest_daily" | grep -oP 'daily-\K[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "")
            if [ -n "$snap_date" ]; then
                snap_epoch=$(date -d "$snap_date" +%s 2>/dev/null || echo "0")
                age_days=$(( (NOW - snap_epoch) / ONE_DAY ))
                if [ "$age_days" -le 1 ]; then
                    log_ok "Latest daily snapshot: $latest_daily (${age_days}d old)"
                elif [ "$age_days" -le 2 ]; then
                    log_warn "Latest daily snapshot: $latest_daily (${age_days}d old - should be fresher)"
                else
                    log_error "Latest daily snapshot: $latest_daily (${age_days}d old - too old!)"
                fi
            else
                log_ok "Latest daily snapshot: $latest_daily"
            fi
        fi

        # Check for weekly snapshots
        weekly_snaps=$(zfs list -H -t snapshot -o name -s creation "$fs" 2>/dev/null | grep "zfs-auto-snap_weekly" | tail -3 || true)
        if [ -z "$weekly_snaps" ]; then
            log_warn "No weekly snapshots found for $fs"
        else
            weekly_count=$(echo "$weekly_snaps" | wc -l)
            log_ok "Found $weekly_count weekly snapshot(s)"
        fi

        # Check for monthly snapshots
        monthly_snaps=$(zfs list -H -t snapshot -o name -s creation "$fs" 2>/dev/null | grep "zfs-auto-snap_monthly" | tail -3 || true)
        if [ -z "$monthly_snaps" ]; then
            log_warn "No monthly snapshots found for $fs"
        else
            monthly_count=$(echo "$monthly_snaps" | wc -l)
            log_ok "Found $monthly_count monthly snapshot(s)"
        fi

        echo
    done
fi

# Check 4: Verify snapshot retention settings
echo "Checking snapshot retention configuration..."
if systemctl cat zfs-auto-snapshot-daily.timer &>/dev/null; then
    log_ok "Auto-snapshot services are configured"

    # Try to extract retention settings from systemd unit files
    for interval in daily weekly monthly; do
        service="zfs-auto-snapshot-${interval}.service"
        if systemctl cat "$service" &>/dev/null; then
            keep=$(systemctl cat "$service" 2>/dev/null | grep -oP -- '--keep=\K[0-9]+' | head -1 || echo "unknown")
            echo "  - $interval: keep $keep snapshots"
        fi
    done
else
    log_error "Auto-snapshot systemd units not found"
fi
echo

# Summary
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_ok "All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    exit 0
else
    echo -e "${RED}Errors: $ERRORS${NC}, ${YELLOW}Warnings: $WARNINGS${NC}"
    exit 1
fi
