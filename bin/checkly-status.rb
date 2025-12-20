#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'time'
require 'zlib'
require 'stringio'

# Checkly status reporter
# Discovers and displays status of all Checkly checks and heartbeats

API_KEY = ENV['CHECKLY_API_KEY']
ACCOUNT_ID = ENV['CHECKLY_ACCOUNT_ID']

unless API_KEY
  puts "ERROR: CHECKLY_API_KEY environment variable not set"
  exit 1
end

def api_request(path)
  uri = URI.parse("https://api.checklyhq.com/v1#{path}")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Authorization'] = "Bearer #{API_KEY}"
  request['x-checkly-account'] = ACCOUNT_ID if ACCOUNT_ID

  response = http.request(request)

  # Decompress if gzipped
  body = response.body
  if response['content-encoding'] == 'gzip'
    gz = Zlib::GzipReader.new(StringIO.new(body))
    body = gz.read
    gz.close
  end

  if response.code.to_i >= 400
    puts "API Error (#{response.code}): #{body}"
    exit 1
  end

  JSON.parse(body)
end

def format_time_ago(timestamp)
  return 'Never' unless timestamp

  time = Time.parse(timestamp)
  seconds = Time.now - time

  case seconds
  when 0..59
    "#{seconds.to_i}s ago"
  when 60..3599
    "#{(seconds / 60).to_i}m ago"
  when 3600..86399
    "#{(seconds / 3600).to_i}h ago"
  else
    "#{(seconds / 86400).to_i}d ago"
  end
rescue
  'Unknown'
end

def status_icon(activated, has_failures = false)
  return '⏸️ ' unless activated
  has_failures ? '❌' : '✅'
end

# Fetch checks
puts "=== Checkly Status Report (homelab) ==="
puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts ""

# Get all checks and filter by homelab tag
begin
  all_checks = api_request('/checks')
  homelab_checks = all_checks.select { |c| c['tags']&.include?('homelab') }
rescue => e
  puts "ERROR fetching checks: #{e.message}"
  homelab_checks = []
end

# Get check statuses
begin
  all_statuses = api_request('/check-statuses')
  status_by_id = all_statuses.each_with_object({}) { |s, h| h[s['checkId']] = s }
rescue => e
  puts "ERROR fetching check statuses: #{e.message}"
  status_by_id = {}
end

# Separate checks by type
url_checks = homelab_checks.select { |c| c['checkType'] == 'API' }
heartbeats = homelab_checks.select { |c| c['checkType'] == 'HEARTBEAT' }

# Display URL checks
if url_checks.any?
  puts "URL Checks (#{url_checks.length}):"
  puts "─" * 80

  url_checks.sort_by { |c| c['name'] }.each do |check|
    activated = check['activated']
    name = check['name']
    url = check.dig('request', 'url') || 'N/A'
    status = status_by_id[check['id']]

    if status
      has_failures = status['hasFailures'] || status['hasErrors']
      icon = status_icon(activated, has_failures)
      last_run = format_time_ago(status['updated_at'])

      puts "#{icon} #{name}"
      puts "    URL: #{url}"
      puts "    Last run: #{last_run}"

      if has_failures
        puts "    ⚠️  FAILING"
      end
    else
      puts "⏳ #{name}"
      puts "    URL: #{url}"
      puts "    Status: No status data"
    end

    puts ""
  end
end

# Display heartbeat checks
if heartbeats.any?
  puts "Heartbeat Monitors (#{heartbeats.length}):"
  puts "─" * 80

  heartbeats.sort_by { |h| h['name'] }.each do |hb|
    activated = hb['activated']
    name = hb['name']
    period = hb.dig('heartbeat', 'period')
    period_unit = hb.dig('heartbeat', 'periodUnit') || 'hours'
    grace = hb.dig('heartbeat', 'grace')
    grace_unit = hb.dig('heartbeat', 'graceUnit') || 'hours'
    status = status_by_id[hb['id']]

    if status
      has_failures = status['hasFailures'] || status['hasErrors']
      icon = status_icon(activated, has_failures)
      last_check = format_time_ago(status['updated_at'])

      puts "#{icon} #{name}"
      puts "    Expected: Every #{period} #{period_unit} (grace: #{grace} #{grace_unit})"
      puts "    Last check: #{last_check}"

      if has_failures
        puts "    ⚠️  ALERT: Heartbeat overdue!"
      end
    else
      puts "⏳ #{name}"
      puts "    Expected: Every #{period} #{period_unit}"
      puts "    Status: No status data"
    end

    puts ""
  end
end

# Summary
puts "─" * 80
total_checks = url_checks.length + heartbeats.length
active_checks = (url_checks + heartbeats).count { |c| c['activated'] }
puts "Total: #{total_checks} checks (#{active_checks} activated)"
puts ""
