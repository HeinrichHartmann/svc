#!/bin/bash
set -e

# Bootstrap Maildir directory structure
mkdir -p /data/Maildir

# Execute mbsync with passed arguments
exec mbsync "$@"
