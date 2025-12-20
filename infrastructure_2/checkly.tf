# Checkly monitoring configuration
# Dynamically discovers services from /svc/services.enabled/*/config.yaml

# Read and parse all service configs
locals {
  services_dir = "/svc/services.enabled"

  # Find all config.yaml files
  config_files = fileset(local.services_dir, "*/config.yaml")

  # Parse configs and extract monitoring settings
  service_configs = {
    for f in local.config_files :
    split("/", f)[0] => yamldecode(file("${local.services_dir}/${f}"))
  }

  # Filter services with monitoring enabled
  monitored_services = {
    for name, config in local.service_configs :
    name => config.monitoring
    if try(config.monitoring.enabled, false)
  }
}

# Private location for home network monitoring
resource "checkly_private_location" "home_network" {
  name      = "Home Network"
  slug_name = "home-network"
  icon      = "home"
}

output "private_location_key" {
  description = "Private location key for agent setup"
  value       = checkly_private_location.home_network.keys
  sensitive   = true
}

# Email alert channel for all checks
resource "checkly_alert_channel" "backup_email" {
  email {
    address = "hhartmann.1729+checkly@gmail.com"
  }
  send_recovery = true
  send_failure  = true
  send_degraded = false
}

# Dynamic URL checks from service configs
resource "checkly_check" "services" {
  for_each = local.monitored_services

  name      = each.value.url
  type      = "API"
  activated = true
  frequency = try(each.value.frequency, 5)

  locations = []
  private_locations = [checkly_private_location.home_network.slug_name]

  tags = ["homelab", each.key, "url-check"]

  request {
    method = "GET"
    url    = each.value.url

    assertion {
      source     = "STATUS_CODE"
      comparison = "EQUALS"
      target     = tostring(try(each.value.expected_status, 200))
    }
  }

  alert_settings {
    escalation_type = "RUN_BASED"

    run_based_escalation {
      failed_run_threshold = 1
    }

    reminders {
      amount   = 1
      interval = 5
    }
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.backup_email.id
    activated  = true
  }
}

# Checkly heartbeat monitors for backup jobs
# These monitors expect a heartbeat ping within 24 hours (+2 hours grace period)

# Heartbeat check for Mail backup
resource "checkly_heartbeat" "mail_backup" {
  name      = "Mail Sync Backup"
  activated = true

  heartbeat {
    period      = 24
    period_unit = "hours"
    grace       = 2
    grace_unit  = "hours"
  }

  tags = ["backup", "mail", "mbsync"]

  alert_settings {
    escalation_type = "RUN_BASED"

    run_based_escalation {
      failed_run_threshold = 1
    }

    reminders {
      amount   = 1
      interval = 5
    }
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.backup_email.id
    activated  = true
  }
}

output "mail_backup_heartbeat_url" {
  description = "Ping this URL after successful Mail backup"
  value       = "https://ping.checklyhq.com/${one(checkly_heartbeat.mail_backup.heartbeat).ping_token}"
  sensitive   = true
}

# Heartbeat check for Prism backup
resource "checkly_heartbeat" "prism_backup" {
  name      = "Prism Originals Backup"
  activated = true

  heartbeat {
    period      = 24
    period_unit = "hours"
    grace       = 2
    grace_unit  = "hours"
  }

  tags = ["backup", "restic", "prism", "photoprism", "media"]

  alert_settings {
    escalation_type = "RUN_BASED"

    run_based_escalation {
      failed_run_threshold = 1
    }

    reminders {
      amount   = 1
      interval = 5
    }
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.backup_email.id
    activated  = true
  }
}

output "prism_backup_heartbeat_url" {
  description = "Ping this URL after successful Prism backup"
  value       = "https://ping.checklyhq.com/${one(checkly_heartbeat.prism_backup.heartbeat).ping_token}"
  sensitive   = true
}

# Heartbeat check for Paperless backup
resource "checkly_heartbeat" "paperless_backup" {
  name      = "Paperless Originals Backup"
  activated = true

  heartbeat {
    period      = 24
    period_unit = "hours"
    grace       = 2
    grace_unit  = "hours"
  }

  tags = ["backup", "restic", "paperless", "media"]

  alert_settings {
    escalation_type = "RUN_BASED"

    run_based_escalation {
      failed_run_threshold = 1
    }

    reminders {
      amount   = 1
      interval = 5
    }
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.backup_email.id
    activated  = true
  }
}

output "paperless_backup_heartbeat_url" {
  description = "Ping this URL after successful Paperless backup"
  value       = "https://ping.checklyhq.com/${one(checkly_heartbeat.paperless_backup.heartbeat).ping_token}"
  sensitive   = true
}
