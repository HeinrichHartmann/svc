#!/usr/bin/env bash
#
# Email Environment Variables Template
# Copy this to email-env.sh and fill in your values
# DO NOT commit email-env.sh - it contains secrets!
#
# Usage: source email-env.sh

# Migadu API credentials (get from Migadu admin panel)
export MIGADU_USERNAME="hhartmann.1729@gmail.com"    # Your Migadu admin email
export MIGADU_TOKEN="YOUR_MIGADU_API_TOKEN_HERE"     # API key from My Account → API Keys

# Mailbox password (used for POP3/SMTP in Gmail)
export TF_VAR_signals_heinrich_password="SECURE_PASSWORD_HERE"  # Password for heinrich@signalsconf.io

echo "Email environment variables set!"
echo "  MIGADU_USERNAME: $MIGADU_USERNAME"
echo "  Passwords: [hidden]"
