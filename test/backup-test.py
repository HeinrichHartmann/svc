#!/usr/bin/env python3
"""
Integration tests for /svc/bin/backup script.

Tests backup and restore functionality using a local restic repository.
"""

import os
import subprocess
import tempfile
import shutil
from pathlib import Path
import pytest


@pytest.fixture
def test_env():
    """
    Set up test environment with temporary directories and cleanup after test.

    Creates:
    - Source directory with test data
    - Restic repository (local filesystem)
    - Restore target directory
    """
    # Create temporary directories
    temp_base = tempfile.mkdtemp(prefix='backup-test-')
    source_dir = Path(temp_base) / 'source'
    repo_dir = Path(temp_base) / 'repo'
    restore_dir = Path(temp_base) / 'restore'

    source_dir.mkdir()
    repo_dir.mkdir()
    restore_dir.mkdir()

    # Create test data
    test_file = source_dir / 'test-data.txt'
    test_content = 'Hello from backup test!\nThis is test data.\n'
    test_file.write_text(test_content)

    # Create nested directory with more test data
    nested_dir = source_dir / 'nested'
    nested_dir.mkdir()
    nested_file = nested_dir / 'nested-file.txt'
    nested_file.write_text('Nested test content\n')

    # Set up environment variables for backup script
    env = os.environ.copy()
    env['BACKUP_REPO'] = str(repo_dir)
    env['RESTIC_PASSWORD'] = 'test-password-12345'
    # Don't send heartbeat in tests
    env.pop('MONITOR_URL', None)

    yield {
        'source_dir': source_dir,
        'repo_dir': repo_dir,
        'restore_dir': restore_dir,
        'test_file': test_file,
        'test_content': test_content,
        'nested_file': nested_file,
        'env': env,
        'temp_base': temp_base,
    }

    # Cleanup
    shutil.rmtree(temp_base, ignore_errors=True)


def run_backup_cmd(args, env, check=True):
    """
    Run the backup script with given arguments.

    Args:
        args: List of arguments to pass to backup script
        env: Environment variables dict
        check: Whether to check return code (default True)

    Returns:
        subprocess.CompletedProcess result
    """
    cmd = ['/svc/bin/backup'] + args
    result = subprocess.run(
        cmd,
        env=env,
        capture_output=True,
        text=True,
        check=check
    )
    return result


def test_backup_restore_cycle(test_env):
    """
    Test complete backup and restore cycle.

    1. Initialize repository
    2. Backup source directory
    3. Verify snapshot was created
    4. Delete source data
    5. Restore from backup
    6. Verify restored data matches original
    """
    source_dir = test_env['source_dir']
    restore_dir = test_env['restore_dir']
    test_content = test_env['test_content']
    env = test_env['env']

    # Step 1: Initialize repository
    print("\n=== Initializing repository ===")
    result = run_backup_cmd(['init'], env)
    assert result.returncode == 0, f"Init failed: {result.stderr}"

    # Step 2: Backup source directory
    print("\n=== Running backup ===")
    result = run_backup_cmd(['backup', str(source_dir)], env)
    assert result.returncode == 0, f"Backup failed: {result.stderr}"
    assert 'Backup completed successfully' in result.stdout or result.returncode == 0

    # Step 3: Verify snapshot was created
    print("\n=== Listing snapshots ===")
    result = run_backup_cmd(['list'], env)
    assert result.returncode == 0, f"List failed: {result.stderr}"
    # Should have at least one snapshot
    assert 'backup-test' in result.stdout or len(result.stdout) > 0

    # Step 4: Get snapshot ID for restore
    result = run_backup_cmd(['list'], env)
    # Parse snapshot ID from output (restic snapshots format)
    # We'll use 'latest' which restic supports
    snapshot_id = 'latest'

    # Step 5: Delete source data to simulate data loss
    print("\n=== Deleting source data ===")
    shutil.rmtree(source_dir)
    assert not source_dir.exists(), "Source directory should be deleted"

    # Step 6: Restore from backup
    print("\n=== Restoring from backup ===")
    result = run_backup_cmd(
        ['restore', snapshot_id, '--target', str(restore_dir)],
        env
    )
    assert result.returncode == 0, f"Restore failed: {result.stderr}"

    # Step 7: Verify restored data
    print("\n=== Verifying restored data ===")

    # Restic restores to <target>/<original-path>
    # So our data will be at restore_dir / source_dir
    restored_source = restore_dir / source_dir.relative_to('/')

    # Check main test file
    restored_test_file = restored_source / 'test-data.txt'
    assert restored_test_file.exists(), f"Restored file not found at {restored_test_file}"

    restored_content = restored_test_file.read_text()
    assert restored_content == test_content, "Restored content doesn't match original"

    # Check nested file
    restored_nested = restored_source / 'nested' / 'nested-file.txt'
    assert restored_nested.exists(), "Restored nested file not found"
    assert 'Nested test content' in restored_nested.read_text()

    print("\n=== Test passed! ===")


def test_backup_requires_volume(test_env):
    """Test that backup command requires volume argument."""
    env = test_env['env']

    # Initialize repo first
    run_backup_cmd(['init'], env)

    # Try backup without volume
    result = run_backup_cmd(['backup'], env, check=False)
    assert result.returncode != 0, "Backup should fail without volume"
    assert 'No volumes specified' in result.stdout or result.returncode != 0


def test_backup_validates_volume_exists(test_env):
    """Test that backup validates volume path exists."""
    env = test_env['env']

    # Initialize repo first
    run_backup_cmd(['init'], env)

    # Try backup with non-existent volume
    result = run_backup_cmd(
        ['backup', '/nonexistent/path/xyz'],
        env,
        check=False
    )
    assert result.returncode != 0, "Backup should fail for non-existent volume"
    assert 'does not exist' in result.stdout or result.returncode != 0


def test_multiple_volumes(test_env):
    """Test backing up multiple volumes."""
    env = test_env['env']

    # Create second source directory
    temp_base = Path(test_env['temp_base'])
    source2_dir = temp_base / 'source2'
    source2_dir.mkdir()
    (source2_dir / 'file2.txt').write_text('Second source\n')

    # Initialize repo
    run_backup_cmd(['init'], env)

    # Backup both volumes
    result = run_backup_cmd([
        'backup',
        str(test_env['source_dir']),
        str(source2_dir)
    ], env)

    assert result.returncode == 0, f"Multi-volume backup failed: {result.stderr}"


def test_stats_command(test_env):
    """Test stats command works."""
    env = test_env['env']

    # Initialize and backup
    run_backup_cmd(['init'], env)
    run_backup_cmd(['backup', str(test_env['source_dir'])], env)

    # Get stats
    result = run_backup_cmd(['stats'], env)
    assert result.returncode == 0, f"Stats failed: {result.stderr}"


if __name__ == '__main__':
    # Allow running directly for debugging
    pytest.main([__file__, '-v', '-s'])
