#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""Samba Health Check - Tests that Samba is running and shares are accessible"""

import subprocess
import sys


def check_service(service_name: str) -> bool:
    """Check if a systemd service is active"""
    try:
        subprocess.run(
            ["systemctl", "is-active", "--quiet", service_name],
            check=True,
            capture_output=True
        )
        print(f"✓ {service_name} is running")
        return True
    except subprocess.CalledProcessError:
        print(f"✗ {service_name} is NOT running")
        return False


def check_ports() -> bool:
    """Check if Samba ports are listening"""
    failed = False
    for port in [139, 445]:
        result = subprocess.run(
            ["ss", "-tlnp"],
            capture_output=True,
            text=True
        )
        if f":{port} " in result.stdout:
            print(f"✓ Port {port} is listening")
        else:
            print(f"✗ Port {port} is NOT listening")
            failed = True
    return not failed


def check_shares() -> bool:
    """Check if Samba shares are accessible"""
    try:
        result = subprocess.run(
            ["smbclient", "-L", "localhost", "-N"],
            capture_output=True,
            text=True,
            check=True
        )
        print("✓ Samba shares are accessible")

        # Extract share names
        shares = []
        for line in result.stdout.split('\n'):
            if 'Disk' in line:
                parts = line.split()
                if parts:
                    shares.append(parts[0])

        if shares:
            print("  Available shares:")
            for share in shares:
                print(f"    - {share}")

        return True
    except subprocess.CalledProcessError:
        print("✗ Cannot list Samba shares")
        return False


def main():
    print("=== Samba Health Check ===")
    print()

    all_passed = True

    # Check services
    all_passed &= check_service("samba-smbd.service")
    all_passed &= check_service("samba-nmbd.service")
    all_passed &= check_service("samba-winbindd.service")

    print()
    all_passed &= check_ports()

    print()
    all_passed &= check_shares()

    print()
    if all_passed:
        print("✓ All Samba checks passed")
        return 0
    else:
        print("✗ Some Samba checks failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
