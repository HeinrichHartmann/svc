#!/usr/bin/env bash
set -euo pipefail

# Restic backup script for mbsync Maildir to Backblaze B2
# Usage: ./backup.sh [backup|list|stats|restore <snapshot-id>]

# Configuration
MAILDIR="${MAILDIR:-/share/hhartmann/var/mbsync/Maildir}"
B2_CREDS="secrets/b2.key"
RESTIC_PASSWORD_FILE="secrets/restic-password"
BACKUP_REPO="s3:s3.us-west-002.backblazeb2.com/hh-mbsync"

# Load B2 credentials
if [[ ! -f "${B2_CREDS}" ]]; then
    echo "ERROR: B2 credentials not found at ${B2_CREDS}"
    exit 1
fi

source "${B2_CREDS}"

# Export AWS-compatible env vars for restic S3 backend
export AWS_ACCESS_KEY_ID="${B2_KEYID}"
export AWS_SECRET_ACCESS_KEY="${B2_KEY}"
export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE}"

# Helper function to run restic
restic_cmd() {
    restic -r "${BACKUP_REPO}" "$@"
}

# Commands
cmd_backup() {
    echo "=== Backing up Maildir to B2 ==="
    echo "Source: ${MAILDIR}"
    echo "Repo: ${BACKUP_REPO}"
    echo ""

    if [[ ! -d "${MAILDIR}" ]]; then
        echo "ERROR: Maildir not found: ${MAILDIR}"
        exit 1
    fi

    restic_cmd backup "${MAILDIR}" \
        --tag mbsync \
        --tag maildir \
        --verbose

    echo ""
    echo "✓ Backup completed successfully"
}

cmd_list() {
    echo "=== Backup snapshots ==="
    restic_cmd snapshots
}

cmd_stats() {
    echo "=== Backup statistics ==="
    restic_cmd stats
}

cmd_restore() {
    local snapshot_id="${1:-}"
    if [[ -z "${snapshot_id}" ]]; then
        echo "ERROR: Snapshot ID required"
        echo "Usage: $0 restore <snapshot-id>"
        echo ""
        echo "Available snapshots:"
        cmd_list
        exit 1
    fi

    echo "=== Restoring snapshot ${snapshot_id} ==="
    echo "WARNING: This will restore to /"
    echo ""

    restic_cmd restore "${snapshot_id}" --target /

    echo ""
    echo "✓ Restore completed successfully"
}

cmd_init() {
    echo "=== Initializing restic repository ==="
    echo "Repo: ${BACKUP_REPO}"
    echo ""

    restic_cmd init

    echo ""
    echo "✓ Repository initialized successfully"
}

cmd_check() {
    echo "=== Checking repository integrity ==="
    restic_cmd check
}

cmd_forget() {
    echo "=== Pruning old snapshots ==="
    echo "Keeping:"
    echo "  - Last 7 daily snapshots"
    echo "  - Last 4 weekly snapshots"
    echo "  - Last 6 monthly snapshots"
    echo ""

    restic_cmd forget \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 6 \
        --prune

    echo ""
    echo "✓ Pruning completed successfully"
}

cmd_ls() {
    local snapshot_id="${1:-latest}"
    local path="${2:-}"

    echo "=== Listing files in snapshot ${snapshot_id} ==="

    if [[ -n "${path}" ]]; then
        restic_cmd ls "${snapshot_id}" "${path}"
    else
        restic_cmd ls "${snapshot_id}"
    fi
}

cmd_find() {
    local pattern="${1:-}"
    if [[ -z "${pattern}" ]]; then
        echo "ERROR: Search pattern required"
        echo "Usage: $0 find <pattern>"
        exit 1
    fi

    echo "=== Searching for: ${pattern} ==="
    restic_cmd find "${pattern}"
}

cmd_diff() {
    local snap1="${1:-}"
    local snap2="${2:-}"

    if [[ -z "${snap1}" || -z "${snap2}" ]]; then
        echo "ERROR: Two snapshot IDs required"
        echo "Usage: $0 diff <snapshot-id-1> <snapshot-id-2>"
        echo ""
        echo "Available snapshots:"
        cmd_list
        exit 1
    fi

    echo "=== Comparing snapshots ==="
    echo "Snapshot 1: ${snap1}"
    echo "Snapshot 2: ${snap2}"
    echo ""

    restic_cmd diff "${snap1}" "${snap2}"
}

# Main
COMMAND="${1:-backup}"

case "${COMMAND}" in
    backup)
        cmd_backup
        ;;
    list|snapshots)
        cmd_list
        ;;
    stats)
        cmd_stats
        ;;
    restore)
        shift
        cmd_restore "$@"
        ;;
    init)
        cmd_init
        ;;
    check)
        cmd_check
        ;;
    forget|prune)
        cmd_forget
        ;;
    ls)
        shift
        cmd_ls "$@"
        ;;
    find)
        shift
        cmd_find "$@"
        ;;
    diff)
        shift
        cmd_diff "$@"
        ;;
    *)
        echo "Usage: $0 {backup|list|stats|restore <id>|init|check|forget|ls|find|diff}"
        echo ""
        echo "Commands:"
        echo "  backup              - Backup Maildir to B2"
        echo "  list                - List backup snapshots"
        echo "  stats               - Show backup statistics"
        echo "  restore <id>        - Restore a snapshot by ID"
        echo "  init                - Initialize repository (first time only)"
        echo "  check               - Check repository integrity"
        echo "  forget              - Prune old snapshots"
        echo "  ls <snapshot> [path] - List files in a snapshot"
        echo "  find <pattern>      - Find files matching pattern"
        echo "  diff <id1> <id2>    - Compare two snapshots"
        exit 1
        ;;
esac
