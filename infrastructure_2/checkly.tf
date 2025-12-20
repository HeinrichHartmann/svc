# Checkly heartbeat monitors for backup jobs
# These monitors expect a heartbeat ping within 24 hours (+2 hours grace period)

# Email alert channel for backup failures
resource "checkly_alert_channel" "backup_email" {
  email {
    address = "hhartmann.1729+checkly@gmail.com"
  }
  send_recovery = true
  send_failure  = true
  send_degraded = false
}

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
