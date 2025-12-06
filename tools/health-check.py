#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""
System Health Check Tool for /svc Infrastructure

Quick health assessment of system state including:
- System uptime and load
- Docker services status
- Systemd service failures
- ZFS pool health
- Network listeners
- Disk usage
- Recent error logs

Usage:
    python3 /svc/tools/health-check.py

Output: JSON to stdout
"""

import subprocess
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

def run_cmd(cmd, shell=True, timeout=5):
    """Execute shell command and return output"""
    try:
        result = subprocess.run(
            cmd,
            shell=shell,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", -1
    except Exception as e:
        return str(e), -1

def get_uptime():
    """Get system uptime information"""
    output, _ = run_cmd("uptime")
    parts = output.split("up")[1].split(",")
    uptime_str = parts[0].strip()

    # Parse load average
    load_avg = output.split("load average:")[1].strip() if "load average:" in output else "unknown"

    return {
        "uptime": uptime_str,
        "load_average": load_avg
    }

def get_docker_status():
    """Get Docker daemon and container status"""
    # Check Docker daemon
    daemon_output, _ = run_cmd("systemctl is-active docker.service")
    daemon_status = daemon_output.strip()

    # Get all containers
    containers_output, _ = run_cmd(
        "docker ps -a --format '{{.Names}}|{{.State}}|{{.Status}}' 2>/dev/null"
    )

    containers = []
    if containers_output:
        for line in containers_output.split('\n'):
            if line:
                parts = line.split('|')
                if len(parts) >= 3:
                    containers.append({
                        "name": parts[0],
                        "state": parts[1],
                        "status": parts[2]
                    })

    # Count by state
    running = sum(1 for c in containers if c["state"] == "running")
    exited = sum(1 for c in containers if c["state"] == "exited")

    return {
        "daemon_status": daemon_status,
        "daemon_running": daemon_status == "active",
        "total_containers": len(containers),
        "running": running,
        "exited": exited,
        "containers": containers
    }

def get_failed_services():
    """Get failed systemd services"""
    output, _ = run_cmd(
        "systemctl list-units --type=service --state=failed --no-pager --no-legend"
    )

    failed = []
    if output:
        for line in output.split('\n'):
            if line.strip():
                parts = line.split()
                if parts:
                    failed.append({
                        "unit": parts[0],
                        "load": parts[1] if len(parts) > 1 else "unknown",
                        "active": parts[2] if len(parts) > 2 else "unknown",
                        "sub": parts[3] if len(parts) > 3 else "unknown"
                    })

    return {
        "count": len(failed),
        "services": failed
    }

def get_zfs_status():
    """Get ZFS pool status"""
    output, returncode = run_cmd("zpool status 2>/dev/null")

    if returncode != 0:
        return {"available": False, "pools": []}

    pools = []
    current_pool = None

    for line in output.split('\n'):
        line = line.strip()
        if line.startswith('pool:'):
            if current_pool:
                pools.append(current_pool)
            current_pool = {
                "name": line.split(':')[1].strip(),
                "state": "unknown",
                "errors": "unknown"
            }
        elif line.startswith('state:') and current_pool:
            current_pool["state"] = line.split(':')[1].strip()
        elif line.startswith('errors:') and current_pool:
            current_pool["errors"] = line.split(':', 1)[1].strip()

    if current_pool:
        pools.append(current_pool)

    return {
        "available": True,
        "pool_count": len(pools),
        "pools": pools,
        "all_online": all(p["state"] == "ONLINE" for p in pools)
    }

def get_disk_usage():
    """Get disk usage for key filesystems"""
    output, _ = run_cmd("df -h /share /svc / 2>/dev/null | tail -n +2")

    filesystems = []
    if output:
        for line in output.split('\n'):
            if line.strip():
                parts = line.split()
                if len(parts) >= 6:
                    filesystems.append({
                        "filesystem": parts[0],
                        "size": parts[1],
                        "used": parts[2],
                        "available": parts[3],
                        "use_percent": parts[4],
                        "mounted_on": parts[5]
                    })

    return filesystems

def get_network_listeners():
    """Get listening ports for key services"""
    output, _ = run_cmd("ss -tlnp 2>/dev/null | grep -E ':(80|443|25565)'")

    listeners = []
    if output:
        for line in output.split('\n'):
            if 'LISTEN' in line:
                # Extract port number
                for port in ['80', '443', '25565']:
                    if f':{port}' in line:
                        service = {
                            '80': 'HTTP',
                            '443': 'HTTPS',
                            '25565': 'Minecraft'
                        }[port]
                        listeners.append({
                            "port": port,
                            "service": service,
                            "listening": True
                        })

    # Add missing services
    for port, service in [('80', 'HTTP'), ('443', 'HTTPS'), ('25565', 'Minecraft')]:
        if not any(l['port'] == port for l in listeners):
            listeners.append({
                "port": port,
                "service": service,
                "listening": False
            })

    return sorted(listeners, key=lambda x: int(x['port']))

def get_svc_enabled_services():
    """Get enabled services in /svc"""
    svc_enabled_path = Path("/svc/services.enabled")

    if not svc_enabled_path.exists():
        return {"available": False, "services": []}

    services = []
    for item in svc_enabled_path.iterdir():
        if item.is_symlink() or item.is_dir():
            if item.name not in ['.', '..']:
                services.append(item.name)

    return {
        "available": True,
        "count": len(services),
        "services": sorted(services)
    }

def get_recent_errors():
    """Get recent error logs"""
    output, _ = run_cmd(
        "journalctl -p err -n 20 --since '24 hours ago' --no-pager 2>/dev/null | grep -v 'i2c i2c-2'"
    )

    lines = []
    if output:
        for line in output.split('\n'):
            if line.strip() and not line.startswith('--'):
                lines.append(line.strip())

    return {
        "count": len(lines),
        "recent": lines[:10]  # Limit to 10 most recent
    }

def get_tailscale_status():
    """Get Tailscale VPN status"""
    output, returncode = run_cmd("tailscale status --json 2>/dev/null", timeout=3)

    if returncode != 0:
        # Fallback to simple status
        simple_output, ret = run_cmd("tailscale status 2>/dev/null | head -1")
        if ret == 0 and simple_output:
            parts = simple_output.split()
            return {
                "connected": True,
                "ip": parts[0] if parts else "unknown",
                "hostname": parts[1] if len(parts) > 1 else "unknown"
            }
        return {"connected": False}

    try:
        data = json.loads(output)
        return {
            "connected": True,
            "ip": data.get("Self", {}).get("TailscaleIPs", ["unknown"])[0],
            "hostname": data.get("Self", {}).get("HostName", "unknown")
        }
    except:
        return {"connected": False}

def get_zfs_auto_snapshot_status():
    """Check ZFS auto-snapshot configuration and recent snapshots"""
    import time

    # Check for filesystems with auto-snapshot enabled
    fs_output, fs_ret = run_cmd(
        "zfs get -H -o name,value com.sun:auto-snapshot | grep -w 'true' | awk '{print $1}' | grep -v '@' 2>/dev/null"
    )

    if fs_ret != 0 or not fs_output:
        return {
            "enabled": False,
            "filesystems": []
        }

    filesystems = [fs.strip() for fs in fs_output.split('\n') if fs.strip()]

    # Check systemd timers
    timers_status = {}
    for interval in ['daily', 'weekly', 'monthly']:
        timer = f"zfs-snapshot-{interval}.timer"
        timer_output, timer_ret = run_cmd(f"systemctl is-active {timer} 2>/dev/null")
        timers_status[interval] = timer_output.strip() == "active"

    # Check for recent snapshots on each filesystem
    fs_with_recent_snaps = []
    fs_without_recent_snaps = []

    now = int(time.time())
    two_days = 2 * 24 * 3600

    for fs in filesystems[:5]:  # Check first 5 to avoid timeout
        snap_output, _ = run_cmd(
            f"zfs list -H -t snapshot -o name -s creation '{fs}' 2>/dev/null | grep 'zfs-auto-snap_daily' | tail -1"
        )

        if snap_output:
            fs_with_recent_snaps.append(fs)
        else:
            fs_without_recent_snaps.append(fs)

    return {
        "enabled": True,
        "filesystem_count": len(filesystems),
        "filesystems": filesystems[:10],  # Limit output
        "timers": timers_status,
        "timers_active": all(timers_status.values()),
        "filesystems_with_snapshots": len(fs_with_recent_snaps),
        "filesystems_without_snapshots": len(fs_without_recent_snaps)
    }

def main():
    """Main health check function"""
    health_data = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "hostname": run_cmd("hostname")[0],
        "system": get_uptime(),
        "docker": get_docker_status(),
        "failed_services": get_failed_services(),
        "zfs": get_zfs_status(),
        "zfs_auto_snapshot": get_zfs_auto_snapshot_status(),
        "disk_usage": get_disk_usage(),
        "network": {
            "listeners": get_network_listeners(),
            "tailscale": get_tailscale_status()
        },
        "svc": get_svc_enabled_services(),
        "errors": get_recent_errors()
    }

    # Calculate overall health
    issues = []

    if not health_data["docker"]["daemon_running"]:
        issues.append("Docker daemon not running")

    if health_data["docker"]["exited"] > 0 and health_data["docker"]["running"] == 0:
        issues.append(f"{health_data['docker']['exited']} Docker containers stopped")

    if health_data["failed_services"]["count"] > 0:
        issues.append(f"{health_data['failed_services']['count']} systemd services failed")

    if health_data["zfs"]["available"] and not health_data["zfs"]["all_online"]:
        issues.append("ZFS pools not all online")

    if health_data["svc"]["count"] == 0:
        issues.append("No /svc services enabled")

    http_listening = any(l["port"] in ["80", "443"] and l["listening"] for l in health_data["network"]["listeners"])
    if not http_listening and health_data["docker"]["running"] > 0:
        issues.append("HTTP/HTTPS not listening despite running containers")

    # Check ZFS auto-snapshot
    if health_data["zfs_auto_snapshot"]["enabled"]:
        if not health_data["zfs_auto_snapshot"]["timers_active"]:
            issues.append("ZFS auto-snapshot timers not active")
        if health_data["zfs_auto_snapshot"]["filesystems_without_snapshots"] > 0:
            issues.append(f"{health_data['zfs_auto_snapshot']['filesystems_without_snapshots']} filesystems missing recent snapshots")

    health_data["summary"] = {
        "healthy": len(issues) == 0,
        "issue_count": len(issues),
        "issues": issues
    }

    # Output JSON
    print(json.dumps(health_data, indent=2))

    # Exit code: 0 if healthy, 1 if issues
    return 0 if len(issues) == 0 else 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(json.dumps({
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }), file=sys.stderr)
        sys.exit(1)
