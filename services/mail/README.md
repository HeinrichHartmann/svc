# Mail Service

Complete mail solution with Gmail sync (mbsync) and webmail access (Roundcube).

## Overview

- **Purpose**: Sync Gmail accounts to local Maildir and provide webmail interface
- **Accounts**: hhartmann.1729@gmail.com, derhein@gmail.com
- **Storage**: `/share/hhartmann/var/mbsync/Maildir`
- **Webmail**: https://mail.heinrichhartmann.net
- **Components**:
  - **mbsync**: Syncs Gmail to Maildir (built from Nix flake)
  - **Dovecot**: IMAP server for reading Maildir
  - **Roundcube**: Webmail interface

## Setup

1. **Build the mbsync Docker image**:
   ```bash
   make build
   ```

2. **Ensure secrets exist**:
   - `/home/hhartmann/box/secrets/gmail_hhartmann1729.key` - App password for hhartmann.1729@gmail.com
   - `/home/hhartmann/box/secrets/gmail_derhein.key` - App password for derhein@gmail.com

3. **Start the mail services**:
   ```bash
   docker compose up -d dovecot roundcube
   ```

4. **Access webmail**: https://mail.heinrichhartmann.net

## Usage

### Syncing Mail

Run a one-time sync:
```bash
make sync
```

Or directly:
```bash
docker compose run --rm mbsync
```

### Accessing Mail

- **Webmail**: Visit https://mail.heinrichhartmann.net
- **Login**:
  - Username: `hhartmann.1729` or `derhein` (matching the Maildir subdirectory name)
  - Password: `mailpass`
  - Server: Leave default (dovecot is auto-configured)

## Configuration

- **mbsyncrc**: Sync configuration (max 200 messages per account)
- **flake.nix**: Nix flake defining the Docker image
- **flake.lock**: Locked dependencies for reproducibility

## Synced Folders

For each account:
- `[Gmail]/All Mail` - All messages
- `[Gmail]/Sent Mail` - Sent messages

Maildir structure:
```
/share/hhartmann/var/mbsync/Maildir/
├── hhartmann/
│   ├── Inbox/
│   ├── [Gmail].All Mail/
│   └── [Gmail].Sent Mail/
└── derhein/
    ├── Inbox/
    ├── [Gmail].All Mail/
    └── [Gmail].Sent Mail/
```

## Notes

- This is a one-shot service (restart: "no")
- Run via cron or manually when you want to sync
- Uses MaxMessages=200 to limit sync (configurable in mbsyncrc)
