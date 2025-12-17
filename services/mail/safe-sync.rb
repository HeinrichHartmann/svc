#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'

# Configuration
MAILDIR = "/share/hhartmann/var/mbsync"
STATE_DIR = "/share/hhartmann/var/mbsync/.local/state/isync"
ZFS_DATASET = "data-iron/share/hhartmann/var/mbsync"
LOCK_FILE = "/tmp/mbsync-safe-sync.lock"

# Cleanup handler
def cleanup(exit_code, snapshot_pre)
  FileUtils.rm_f(LOCK_FILE)
  if exit_code != 0
    puts "ERROR: Sync failed with exit code #{exit_code}"
    if snapshot_pre
      puts "Pre-sync snapshot available: #{snapshot_pre}"
      puts "To rollback: zfs rollback #{ZFS_DATASET}@#{snapshot_pre}"
    end
  end
  exit(exit_code)
end

puts "=== Safe mbsync with ZFS snapshots (Ruby) ==="
puts

# 1. Acquire exclusive lock
puts "[1/6] Acquiring exclusive lock..."
lock_file = File.open(LOCK_FILE, File::CREAT | File::WRONLY)
unless lock_file.flock(File::LOCK_EX | File::LOCK_NB)
  puts "ERROR: Another sync is already running"
  exit(1)
end
puts "✓ Lock acquired"
puts

snapshot_pre = nil

begin
  # 2. Verify no mbsync processes running
  puts "[2/6] Checking for running mbsync processes..."
  mbsync_pids = `pgrep -f mbsync`.strip
  unless mbsync_pids.empty?
    puts "ERROR: mbsync process already running:"
    puts `pgrep -af mbsync`
    cleanup(1, snapshot_pre)
  end
  puts "✓ No mbsync processes found"
  puts

  # 3. Check filesystem state
  puts "[3/6] Checking filesystem state..."

  # Check for lock-like files
  if File.directory?(STATE_DIR)
    lock_files = Dir.glob(File.join(STATE_DIR, "**", "{*.lock,*~,*.new}"))
    unless lock_files.empty?
      puts "ERROR: Found suspicious state files:"
      lock_files.each { |f| puts "  #{f}" }
      cleanup(1, snapshot_pre)
    end
  end

  # Record state before sync
  msg_count_before = Dir.glob(File.join(MAILDIR, "Maildir", "**", "*:2,*")).length rescue 0
  size_before = `du -sb #{MAILDIR} 2>/dev/null | cut -f1`.strip.to_i rescue 0
  puts "✓ Filesystem state OK"
  puts "  Messages before: #{msg_count_before}"
  puts "  Size before: #{size_before} bytes"
  puts

  # 4. Create pre-sync snapshot
  snapshot_pre = "mbsync-pre-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  puts "[4/6] Creating ZFS snapshot: #{snapshot_pre}"
  unless system("sudo zfs snapshot #{ZFS_DATASET}@#{snapshot_pre}")
    puts "ERROR: Failed to create pre-sync snapshot"
    cleanup(1, snapshot_pre)
  end
  puts "✓ Pre-sync snapshot created"
  puts

  # 5. Run mbsync with full error checking
  puts "[5/6] Running mbsync..."
  sync_log = Tempfile.new('sync-log')
  sync_log.close

  sync_exit = system("timeout 3600 docker compose run --rm mbsync -a >#{sync_log.path} 2>&1")
  sync_exit_code = $?.exitstatus

  puts
  puts "Analyzing sync results..."

  # Check timeout
  if sync_exit_code == 124
    puts "ERROR: Sync timed out after 1 hour"
    puts File.read(sync_log.path)
    cleanup(1, snapshot_pre)
  end

  # Check exit code
  if sync_exit_code != 0
    puts "ERROR: mbsync exited with code #{sync_exit_code}"
    puts File.read(sync_log.path)
    cleanup(1, snapshot_pre)
  end

  # Check for errors in output (commented out for now)
  # sync_output = File.read(sync_log.path)
  # if sync_output =~ /error|fatal|failed|abort/i
  #   puts "ERROR: Found error indicators in output:"
  #   puts sync_output.lines.grep(/error|fatal|failed|abort/i)
  #   cleanup(1, snapshot_pre)
  # end

  # Verify no locks left behind
  if File.directory?(STATE_DIR)
    lock_files = Dir.glob(File.join(STATE_DIR, "**", "{*.lock,*~,*.new}"))
    unless lock_files.empty?
      puts "ERROR: Lock files present after sync!"
      lock_files.each { |f| puts "  #{f}" }
      cleanup(1, snapshot_pre)
    end
  end

  # Verify filesystem changes
  msg_count_after = Dir.glob(File.join(MAILDIR, "Maildir", "**", "*:2,*")).length rescue 0
  size_after = `du -sb #{MAILDIR} 2>/dev/null | cut -f1`.strip.to_i rescue 0

  sync_output = File.read(sync_log.path)
  pulled = sync_output[/(\d+) new message/, 1].to_i rescue 0
  expunged = sync_output[/expunged (\d+)/, 1].to_i rescue 0

  puts "✓ Sync completed successfully"
  puts "  Messages before: #{msg_count_before}"
  puts "  Messages after:  #{msg_count_after}"
  puts "  Messages pulled: #{pulled}"
  puts "  Messages expunged: #{expunged}"
  puts "  Size change: #{size_after - size_before} bytes"
  puts

  sync_log.unlink

  # 6. Create post-sync snapshot
  snapshot_post = "mbsync-post-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  puts "[6/6] Creating ZFS snapshot: #{snapshot_post}"
  unless system("sudo zfs snapshot #{ZFS_DATASET}@#{snapshot_post}")
    puts "ERROR: Failed to create post-sync snapshot"
    cleanup(1, snapshot_pre)
  end
  puts "✓ Post-sync snapshot created"
  puts

  puts "=== Sync completed successfully ==="
  puts "Pre-snapshot:  #{snapshot_pre}"
  puts "Post-snapshot: #{snapshot_post}"
  puts
  puts "To list snapshots: zfs list -t snapshot #{ZFS_DATASET}"
  puts "To rollback: zfs rollback #{ZFS_DATASET}@#{snapshot_pre}"
  puts "To delete old snapshots: zfs destroy #{ZFS_DATASET}@#{snapshot_pre}"

  cleanup(0, snapshot_pre)

rescue => e
  puts "ERROR: Unexpected exception: #{e.message}"
  puts e.backtrace
  cleanup(1, snapshot_pre)
end
