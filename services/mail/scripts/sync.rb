#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'net/http'
require 'uri'

# Configuration - environment variables with defaults
MAILDIR = ENV.fetch('MAILDIR', '/share/hhartmann/var/mbsync')
STATE_DIR = ENV.fetch('STATE_DIR', File.join(MAILDIR, '.local/state/isync'))
ZFS_DATASET = ENV.fetch('ZFS_DATASET', 'data-iron/share/hhartmann/var/mbsync')
ZFS_CMD = ENV.fetch('ZFS_CMD', '/run/current-system/sw/bin/zfs')
LOCK_FILE = ENV.fetch('LOCK_FILE', '/tmp/mbsync.lock')
MBSYNC_CONFIG = ENV.fetch('MBSYNC_CONFIG', 'config/mbsyncrc')
MONITOR_URL = ENV['MONITOR_URL']
SYNC_TIMEOUT = ENV.fetch('SYNC_TIMEOUT', '3600').to_i

# Helper to log with timestamp
def log(msg)
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  puts "[#{timestamp}] #{msg}"
end

# Send heartbeat to monitoring service with retry
def send_heartbeat
  return unless MONITOR_URL && !MONITOR_URL.empty?
  attempt = 0
  begin
    attempt += 1
    uri = URI.parse(MONITOR_URL)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                    open_timeout: 5, read_timeout: 5) do |http|
      response = http.get(uri.request_uri)
      response.value  # Raises error if not 2xx
      log "✓ Heartbeat sent"
    end
  rescue => e
    if attempt < 3
      sleep 1
      retry
    else
      log "⚠ Heartbeat failed: #{e.message}"
    end
  end
end

log "=== Mbsync started ==="

# 1. Acquire exclusive lock
lock_file = File.open(LOCK_FILE, File::CREAT | File::WRONLY)
unless lock_file.flock(File::LOCK_EX | File::LOCK_NB)
  log "ERROR: Another sync is already running"
  exit(1)
end

snapshot_pre = nil
snapshot_post = nil

begin
  # Check for stale lock files
  if File.directory?(STATE_DIR)
    lock_files = Dir.glob(File.join(STATE_DIR, "**", "{*.lock,*~,*.new}"))
    unless lock_files.empty?
      log "ERROR: Found state lock files"
      exit(1)
    end
  end

  # Record state before sync
  msg_count_before = Dir.glob("volumes/Maildir/**/*:2,*").length rescue 0

  # === STEP 1: Pre-sync snapshot ===
  snapshot_pre = "mbsync-pre-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  log "Creating pre-sync snapshot: #{snapshot_pre}"
  unless system("#{ZFS_CMD} snapshot #{ZFS_DATASET}@#{snapshot_pre}")
    log "ERROR: Failed to create pre-sync snapshot"
    exit(1)
  end
  log "✓ Snapshot created"

  # === STEP 2: Run mbsync ===
  log "Running mbsync..."
  sync_log = Tempfile.new('sync-log')
  sync_log.close

  # Find mbsync command
  mbsync_cmd = if system('command -v mbsync >/dev/null 2>&1')
    'mbsync'
  else
    'nix run nixpkgs#isync -- mbsync'
  end

  sync_exit = system("timeout #{SYNC_TIMEOUT} #{mbsync_cmd} -c '#{MBSYNC_CONFIG}' -V -a >#{sync_log.path} 2>&1")
  sync_exit_code = $?.exitstatus

  # Check for failure
  if sync_exit_code == 124
    log "ERROR: Sync timed out"
    log "Rolling back to: #{snapshot_pre}"
    system("#{ZFS_CMD} rollback #{ZFS_DATASET}@#{snapshot_pre}")
    exit(1)
  end

  if sync_exit_code != 0
    log "ERROR: mbsync failed (exit #{sync_exit_code})"
    sync_output = File.read(sync_log.path)
    log "Output: #{sync_output.lines.last(5).join}"
    log "Rolling back to: #{snapshot_pre}"
    system("#{ZFS_CMD} rollback #{ZFS_DATASET}@#{snapshot_pre}")
    exit(1)
  end

  # Verify no locks left behind
  if File.directory?(STATE_DIR)
    lock_files = Dir.glob(File.join(STATE_DIR, "**", "{*.lock,*~,*.new}"))
    unless lock_files.empty?
      log "ERROR: Lock files remain after sync"
      log "Rolling back to: #{snapshot_pre}"
      system("#{ZFS_CMD} rollback #{ZFS_DATASET}@#{snapshot_pre}")
      exit(1)
    end
  end

  # Count synced messages
  msg_count_after = Dir.glob("volumes/Maildir/**/*:2,*").length rescue 0
  pulled = msg_count_after - msg_count_before

  log "✓ Synced #{pulled} messages"

  sync_log.unlink

  # === STEP 3: Post-sync snapshot ===
  snapshot_post = "mbsync-post-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  log "Creating post-sync snapshot: #{snapshot_post}"
  unless system("#{ZFS_CMD} snapshot #{ZFS_DATASET}@#{snapshot_post}")
    log "ERROR: Failed to create post-sync snapshot"
    exit(1)
  end
  log "✓ Snapshot created"

  # === STEP 4: Cleanup pre-sync snapshot ===
  log "Cleaning up pre-sync snapshot: #{snapshot_pre}"
  system("sudo #{ZFS_CMD} destroy #{ZFS_DATASET}@#{snapshot_pre}")

  # === STEP 5: Send success heartbeat ===
  log "✓ Sync complete"
  send_heartbeat

rescue => e
  log "ERROR: Unexpected exception: #{e.message}"
  log e.backtrace.join("\n")
  if snapshot_pre
    log "Rolling back to: #{snapshot_pre}"
    system("#{ZFS_CMD} rollback #{ZFS_DATASET}@#{snapshot_pre}")
  end
  exit(1)
ensure
  FileUtils.rm_f(LOCK_FILE)
end
