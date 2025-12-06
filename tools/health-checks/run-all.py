#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""Run all health checks and report status"""

import subprocess
import sys
from pathlib import Path


def run_check(script_path: Path) -> tuple[str, bool]:
    """Run a single health check script and return (name, passed)"""
    name = script_path.stem
    try:
        result = subprocess.run(
            [str(script_path)],
            capture_output=True,
            text=True,
            timeout=30
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return (name, result.returncode == 0)
    except subprocess.TimeoutExpired:
        print(f"✗ {name} health check timed out")
        return (name, False)
    except Exception as e:
        print(f"✗ {name} health check failed: {e}")
        return (name, False)


def main():
    print("=" * 60)
    print("Running all health checks")
    print("=" * 60)
    print()

    # Find all .py health check scripts (except this one)
    health_checks_dir = Path(__file__).parent
    scripts = sorted(health_checks_dir.glob("*.py"))
    scripts = [s for s in scripts if s.name != "run-all.py"]

    if not scripts:
        print("No health check scripts found")
        return 1

    results = []
    for script in scripts:
        name, passed = run_check(script)
        results.append((name, passed))
        print()

    # Summary
    print("=" * 60)
    print("Health Check Summary")
    print("=" * 60)

    all_passed = True
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status} - {name}")
        all_passed &= passed

    print()
    if all_passed:
        print("✓ All health checks passed")
        return 0
    else:
        print("✗ Some health checks failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
