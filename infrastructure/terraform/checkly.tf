# Checkly monitoring configuration
# API key via environment variable: CHECKLY_API_KEY

provider "checkly" {
  account_id = var.checkly_account_id
}

variable "checkly_account_id" {
  description = "Checkly account ID"
  type        = string
}

# Heartbeat check for restic backup
resource "checkly_heartbeat" "restic_backup" {
  name      = "Restic Daily Backup"
  activated = true

  heartbeat {
    period      = 24
    period_unit = "hours"
    grace       = 2
    grace_unit  = "hours"
  }

  tags = ["backup", "restic", "pve"]
}

output "restic_heartbeat_url" {
  description = "Ping this URL after successful backup"
  value       = "https://ping.checklyhq.com/${one(checkly_heartbeat.restic_backup.heartbeat).ping_token}"
  sensitive   = true
}
