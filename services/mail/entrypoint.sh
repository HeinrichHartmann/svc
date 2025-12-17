#!/bin/bash
set -e

# Create Maildir parent directory if it doesn't exist
mkdir -p /data/Maildir

# Run mbsync with all arguments
exec mbsync "$@"
