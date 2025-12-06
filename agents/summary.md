# SVC - Service Management System Summary

**Quick Start Documentation for AI Agents**

This document provides context about the `/svc` repository structure, design principles, and usage patterns for future AI agent sessions.

## References
- Blog Post: https://heinrichhartmann.com/posts/home-lab-2023/
- GitHub: https://github.com/HeinrichHartmann/svc
- Local README: `/svc/README.md`

---

## Overview

The `/svc` directory contains a home lab infrastructure management system designed for:
1. **Easy service deployment** - Containerized services with standardized structure
2. **Family-friendly access** - Services accessible across devices without IP/port management
3. **Safe data backup** - Automated backups with clear storage tiers

**Philosophy:** Self-contained, declarative configuration with minimal external dependencies.

---

## Architecture Components

### 1. Host System
- **OS:** NixOS (declarative machine configuration)
- **Why:** Enables quick hardware migrations with config files instead of provisioning scripts
- **Location:** Host configuration managed separately (see `/infra` if needed)

### 2. Networking & Access

**Tailscale VPN:**
- Provides secure remote access without exposing services to internet
- Services accessible via: `$service.heinrichhartmann.net`

**Local Network:**
- Services accessible via: `$service.lan.heinrichhartmann.net`

**DNS:**
- Managed via AWS Route53 (configured with Terraform in `/infra/aws`)
- Public DNS points to Tailscale/local IPs

**Why not self-hosted DNS/PKI?**
Many clients (Firefox, Safari on mobile) ignore DHCP DNS and custom root certificates. Using AWS + Let's Encrypt avoids these issues.

### 3. Ingress & HTTPS

**Traefik** acts as reverse proxy:
- Terminates HTTPS with Let's Encrypt certificates
- Routes requests based on HTTP HOST header
- Dynamic service discovery via Docker labels
- Certificates stored in `/svc/var`

**Certificate renewal:** `make certs` from `/svc`

### 4. Storage Architecture

**ZFS mirrored pool (8TB)** with three-tier strategy:

| Tier | Path | Purpose | Snapshot | Backup |
|------|------|---------|----------|--------|
| **Shelf** | `/share/shelf` | Daily-use working files | ✓ | ✓ (Restic→Backblaze) |
| **Attic** | `/share/attic` | Archived valuables, photos | ✓ | ✓ (Restic→Backblaze) |
| **Garage** | `/share/garage` | Non-critical bulk data | ✓ | ✗ |

**Metaphor:** Shelf = daily use (can get scratched), Attic = safe storage, Garage = acceptable loss

### 5. Secrets Management

- Uses `git-crypt` to encrypt files ending in `.crypt`
- GPG key-based trust model for host authorization
- See `/svc/crypt/README.md` for details

**Trust workflow:**
1. New host: Generate GPG keys, add public key to repo
2. Trusted host: Pull and mark new keys as trusted
3. New host: Pull again to decrypt secrets

---

## Service Management

### Directory Structure

```
/svc/
├── services/              # Available service definitions
│   ├── _template/        # Template for new services
│   ├── docker/           # Docker registry/services
│   ├── traefik/          # Ingress proxy
│   ├── monitoring/       # Monitoring stack
│   └── ...
├── services.enabled/     # Symlinks to enabled services
├── var/                  # Service data and certificates
├── mnt/                  # Bind mount points (if needed)
└── svc.sh               # Service management script
```

### Service Structure

Each service in `/svc/services/$name/` contains:

**1. docker-compose.yaml** - Service definition with Traefik labels:

```yaml
version: '3'
services:
  app:
    image: some/image:latest
    volumes:
      - ./data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.books.rule=HostRegexp(`books.{domain:.*}`)"
      - "traefik.http.routers.books.entrypoints=https"
      - "traefik.http.routers.books.tls=true"
```

**2. Makefile** - Standardized targets:

```makefile
start:
	docker-compose up -d

stop:
	docker-compose down

test:
	@docker-compose ps | grep -q "Up" && echo "OK: Service running" || echo "FAIL: Service down"
```

### Management Commands

```bash
# Service lifecycle
./svc.sh new $name           # Create new service from template
./svc.sh enable $name        # Enable service (creates symlink)
./svc.sh disable $name       # Disable service
./svc.sh list                # List enabled services
./svc.sh list-available      # List all available services

# Bulk operations
make start                   # Start all enabled services
make stop                    # Stop all enabled services
make test                    # Test all services, print status
make certs                   # Renew Let's Encrypt certificates
```

---

## Design Principles

### 1. Self-Contained Configuration
- Everything under `/svc` (not `$HOME/svc`)
- Bind mounts only in `/svc/mnt` (cleanup: unmount)
- Scratch files only in `/svc/var` (cleanup: prune volumes)
- Services use relative paths within their directories

**Rationale:** Conceptually configuring the node itself, not one user's services.

### 2. Minimal External Dependencies
- Avoid bind mounts where possible
- Keep service data in Docker volumes or `/svc/var`
- Services should be self-contained

### 3. Standard Interface
Every service exposes: `make start`, `make stop`, `make test`

### 4. Declarative Over Imperative
- Docker Compose for service definition
- Traefik labels for routing (not config files)
- Infrastructure as code (Terraform)

---

## Common Patterns

### Adding a New Service

```bash
# 1. Create from template
cd /svc
./svc.sh new myservice

# 2. Edit configuration
cd services/myservice
# Edit docker-compose.yaml
# Edit Makefile if needed

# 3. Enable and start
./svc.sh enable myservice
make start

# 4. Test
make test
```

### Traefik Routing Labels

**Basic HTTPS service:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=HostRegexp(`myapp.{domain:.*}`)"
  - "traefik.http.routers.myapp.entrypoints=https"
  - "traefik.http.routers.myapp.tls=true"
```

**With HTTP Basic Auth:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=HostRegexp(`myapp.{domain:.*}`)"
  - "traefik.http.routers.myapp.entrypoints=https"
  - "traefik.http.routers.myapp.tls=true"
  - "traefik.http.routers.myapp.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=user:hashedpassword"
```

### Storage Decisions

**Choose tier based on data value:**
- **Critical, frequently accessed** → `/share/shelf` (backed up, replicated)
- **Critical, archived** → `/share/attic` (backed up, not replicated)
- **Nice to have, bulk data** → `/share/garage` (snapshotted only)

---

## Known Issues & Open Ends

### From Original Documentation

1. **No key retirement mechanism** for git-crypt secrets
2. **OAuth missing** - Traefik OAuth plugin is proprietary with unclear pricing
3. **File replication broken** - Dropbox dropped ZFS support, Syncthing proved unreliable
4. **Service discovery debugging** - Traefik label debugging can be tedious (no linting)

### Lessons Learned

- **Don't self-host DNS/PKI** - Client compatibility issues not worth the effort
- **External services for critical infrastructure** - AWS Route53 more reliable than DHCP/DNS
- **Traefik > Nginx/HAProxy** - Simpler maintenance with Docker labels
- **NixOS declarative config** - Faster hardware migrations than provisioning scripts

---

## Quick Reference: File Locations

```
/svc/                          # Service management root
/svc/services/$name/           # Service definitions
/svc/services.enabled/         # Enabled services (symlinks)
/svc/var/                      # Service data, certificates
/svc/mnt/                      # Bind mounts (if unavoidable)
/svc/svc.sh                    # Service management tool
/svc/Makefile                  # Bulk operations
/svc/crypt/                    # Secrets management
/svc/infra/aws/                # Terraform for AWS resources

/share/shelf/                  # Daily-use files (backed up)
/share/attic/                  # Archived valuables (backed up)
/share/garage/                 # Bulk data (snapshot only)
```

---

## Tips for AI Agents

1. **Check enabled services first:** `ls -la /svc/services.enabled/`
2. **Use the template:** Don't create services from scratch, use `./svc.sh new`
3. **Follow the patterns:** Look at existing services for examples
4. **Test before enabling:** Verify `make start && make test` works before enabling
5. **Keep it simple:** Avoid over-engineering, follow existing patterns
6. **Storage tier matters:** Choose appropriate tier based on backup needs
7. **Traefik labels:** Match the patterns in existing services (docker, monitoring, etc.)

---

**Last Updated:** 2025-11-30
**Maintained by:** Heinrich Hartmann
**Repository:** https://github.com/HeinrichHartmann/svc
