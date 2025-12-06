# Health Check Tool

**Location:** `/svc/tools/health-check.py`

## Purpose

Single-command system health assessment for AI agents to quickly understand the current state of the infrastructure without running dozens of individual commands.

## Usage

```bash
/svc/tools/health-check.py
```

**Output:** JSON to stdout
**Exit Code:** 0 if healthy, 1 if issues detected

## What It Checks

### System Health
- Uptime and load average
- Hostname

### Docker Services
- Docker daemon status
- All container states (running/exited)
- Container count by state

### Systemd Services
- Failed service units
- Service details (load, active, sub state)

### Storage
- ZFS pool status and health
- Disk usage for key filesystems (`/`, `/share`, `/svc`)

### Network
- HTTP (80), HTTPS (443), Minecraft (25565) listeners
- Tailscale VPN connection status

### /svc Services
- Enabled services count
- List of enabled service names

### Error Logs
- Recent error log entries (last 24 hours)
- Filtered to exclude known harmless errors (i2c bus)

### Summary
- Overall health status (boolean)
- Issue count
- List of detected issues

## Output Format

```json
{
  "timestamp": "2025-12-02T15:09:51+00:00",
  "hostname": "qve",
  "system": {
    "uptime": "28 days 3:55",
    "load_average": "0.50, 0.23, 0.19"
  },
  "docker": {
    "daemon_status": "active",
    "daemon_running": true,
    "total_containers": 8,
    "running": 0,
    "exited": 8,
    "containers": [...]
  },
  "failed_services": {
    "count": 2,
    "services": [...]
  },
  "zfs": {
    "available": true,
    "pool_count": 2,
    "pools": [...],
    "all_online": true
  },
  "disk_usage": [...],
  "network": {
    "listeners": [...],
    "tailscale": {...}
  },
  "svc": {
    "available": true,
    "count": 0,
    "services": []
  },
  "errors": {
    "count": 0,
    "recent": []
  },
  "summary": {
    "healthy": false,
    "issue_count": 3,
    "issues": [
      "8 Docker containers stopped",
      "2 systemd services failed",
      "No /svc services enabled"
    ]
  }
}
```

## Performance

- Typical execution time: < 2 seconds
- Timeout per command: 5 seconds (configurable)
- Total timeout: ~15 seconds max

## Implementation Notes

- **Language:** Python 3
- **Dependencies:** None (uses standard library only)
- **Execution:** Via `nix-shell` shebang for NixOS compatibility
- **Error Handling:** Graceful fallbacks for missing commands
- **JSON Output:** Clean, parseable structured data

## AI Agent Usage Pattern

Instead of running 10-20 separate commands like:
```bash
uptime
docker ps -a
systemctl list-units --state=failed
zpool status
df -h
ss -tlnp
journalctl -p err
# ... etc
```

Just run:
```bash
/svc/tools/health-check.py
```

Parse the JSON output and immediately understand:
- What's working
- What's broken
- What needs attention

## Common Health Issues Detected

1. **Docker containers stopped** - Services exited after reboot
2. **Systemd services failed** - Units in failed state
3. **No /svc services enabled** - Nothing in services.enabled/
4. **HTTP/HTTPS not listening** - Traefik not running
5. **ZFS pools degraded** - Storage issues
6. **High disk usage** - Filesystem nearly full

## Extending the Tool

To add new checks:

1. Create a new function `get_your_check()` that returns a dict
2. Add it to `health_data` in `main()`
3. Optionally add issue detection logic to the summary section

Example:
```python
def get_your_check():
    """Check something new"""
    output, returncode = run_cmd("your-command")
    return {
        "status": "ok" if returncode == 0 else "fail",
        "data": output
    }

# In main():
health_data["your_check"] = get_your_check()
```

## Troubleshooting

**Script doesn't run:**
- Check it's executable: `chmod +x /svc/tools/health-check.py`
- Verify nix-shell available: `which nix-shell`

**Timeout errors:**
- Increase timeout in `run_cmd()` calls
- Check if commands are hanging

**Missing data:**
- Check if the command exists on the system
- Verify permissions to run the command

## Related Documentation

- System overview: `/svc/agents/summary.md`
- Service management: `/svc/README.md`
- Tools directory: `/svc/tools/`

---

**Created:** 2025-12-02
**Last Updated:** 2025-12-02
**Maintained by:** AI Agents / Heinrich Hartmann
