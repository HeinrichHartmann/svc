#!/usr/bin/env bash
set -euo pipefail

MAILDIR="/share/hhartmann/var/mbsync"
STATE_DIR="/share/hhartmann/var/mbsync/.local/state/isync"
ZFS_DATASET="data-iron/share/hhartmann/var/mbsync"
LOCK_FILE="/tmp/mbsync-safe-sync.lock"
WORK_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    local exit_code=$?
    rm -rf "$WORK_DIR"
    rm -f "$LOCK_FILE"
    if [ $exit_code -ne 0 ]; then
        echo "ERROR: Sync failed with exit code $exit_code"
        if [ -n "${SNAPSHOT_PRE:-}" ]; then
            echo "Pre-sync snapshot available: $SNAPSHOT_PRE"
            echo "To rollback: zfs rollback $ZFS_DATASET@$SNAPSHOT_PRE"
        fi
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

echo "=== Safe mbsync with ZFS snapshots (v2) ==="
echo

# 1. Acquire exclusive lock
echo "[1/6] Acquiring exclusive lock..."
if ! flock -n 200; then
    echo "ERROR: Another sync is already running"
    exit 1
fi 200>"$LOCK_FILE"
echo "✓ Lock acquired"
echo

# 2. Verify no mbsync processes running
echo "[2/6] Checking for running mbsync processes..."
if pgrep -f "mbsync" >/dev/null 2>&1; then
    echo "ERROR: mbsync process already running:"
    pgrep -af "mbsync"
    exit 1
fi
echo "✓ No mbsync processes found"
echo

# 3. Check filesystem state
echo "[3/6] Checking filesystem state..."
# Check for any lock-like files
if find "$STATE_DIR" -type f \( -name "*.lock" -o -name "*~" -o -name "*.new" \) 2>/dev/null | grep -q .; then
    echo "ERROR: Found suspicious state files:"
    find "$STATE_DIR" -type f \( -name "*.lock" -o -name "*~" -o -name "*.new" \)
    exit 1
fi

# Record state before sync
MSG_COUNT_BEFORE=$(find "$MAILDIR/Maildir" -type f -name "*:2,*" 2>/dev/null | wc -l || echo 0)
SIZE_BEFORE=$(du -sb "$MAILDIR" 2>/dev/null | cut -f1 || echo 0)
echo "✓ Filesystem state OK"
echo "  Messages before: $MSG_COUNT_BEFORE"
echo "  Size before: $SIZE_BEFORE bytes"
echo

# 4. Create pre-sync snapshot
SNAPSHOT_PRE="mbsync-pre-$(date +%Y%m%d-%H%M%S)"
echo "[4/6] Creating ZFS snapshot: $SNAPSHOT_PRE"
if ! sudo zfs snapshot "$ZFS_DATASET@$SNAPSHOT_PRE"; then
    echo "ERROR: Failed to create pre-sync snapshot"
    exit 1
fi
echo "✓ Pre-sync snapshot created"
echo

# 5. Run mbsync with full error checking
echo "[5/6] Running mbsync..."
SYNC_LOG="$WORK_DIR/sync.log"
SYNC_EXIT=0

# Run with timeout to prevent hanging (with verbose output)
if timeout 3600 docker compose run --rm mbsync -V -a >"$SYNC_LOG" 2>&1; then
    SYNC_EXIT=0
else
    SYNC_EXIT=$?
fi

# Detailed analysis of sync results
echo
echo "Analyzing sync results..."

# Check timeout
if [ $SYNC_EXIT -eq 124 ]; then
    echo "ERROR: Sync timed out after 1 hour"
    cat "$SYNC_LOG"
    exit 1
fi

# Check exit code
if [ $SYNC_EXIT -ne 0 ]; then
    echo "ERROR: mbsync exited with code $SYNC_EXIT"
    cat "$SYNC_LOG"
    exit 1
fi

# Check for errors in output (skip validation for now)
# if grep -Eqi "error|fatal|failed|abort" "$SYNC_LOG"; then
#     echo "ERROR: Found error indicators in output:"
#     grep -Ei "error|fatal|failed|abort" "$SYNC_LOG"
#     exit 1
# fi

# Verify no locks left behind
if find "$STATE_DIR" -type f \( -name "*.lock" -o -name "*~" -o -name "*.new" \) 2>/dev/null | grep -q .; then
    echo "ERROR: Lock files present after sync!"
    find "$STATE_DIR" -type f \( -name "*.lock" -o -name "*~" -o -name "*.new" \)
    exit 1
fi

# Verify filesystem changes
MSG_COUNT_AFTER=$(find "$MAILDIR/Maildir" -type f -name "*:2,*" 2>/dev/null | wc -l || echo 0)
SIZE_AFTER=$(du -sb "$MAILDIR" 2>/dev/null | cut -f1 || echo 0)

PULLED=$(grep "pulled" "$SYNC_LOG" | tail -1 | grep -o "[0-9]* new message" | cut -d' ' -f1 || echo 0)
EXPUNGED=$(grep "expunged" "$SYNC_LOG" | tail -1 | grep -o "expunged [0-9]*" | cut -d' ' -f2 || echo 0)

echo "✓ Sync completed successfully"
echo "  Messages before: $MSG_COUNT_BEFORE"
echo "  Messages after:  $MSG_COUNT_AFTER"
echo "  Messages pulled: $PULLED"
echo "  Messages expunged: $EXPUNGED"
echo "  Size change: $((SIZE_AFTER - SIZE_BEFORE)) bytes"
echo

# 6. Create post-sync snapshot
SNAPSHOT_POST="mbsync-post-$(date +%Y%m%d-%H%M%S)"
echo "[6/6] Creating ZFS snapshot: $SNAPSHOT_POST"
if ! sudo zfs snapshot "$ZFS_DATASET@$SNAPSHOT_POST"; then
    echo "ERROR: Failed to create post-sync snapshot"
    exit 1
fi
echo "✓ Post-sync snapshot created"
echo

echo "=== Sync completed successfully ==="
echo "Pre-snapshot:  $SNAPSHOT_PRE"
echo "Post-snapshot: $SNAPSHOT_POST"
echo
echo "To list snapshots: zfs list -t snapshot $ZFS_DATASET"
echo "To rollback: zfs rollback $ZFS_DATASET@$SNAPSHOT_PRE"
echo "To delete old snapshots: zfs destroy $ZFS_DATASET@$SNAPSHOT_PRE"
