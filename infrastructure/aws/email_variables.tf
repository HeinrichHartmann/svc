# Email-related variables
# Set these via environment variables (TF_VAR_*) or terraform.tfvars

variable "signals_heinrich_password" {
  type        = string
  sensitive   = true
  description = "Password for heinrich@signalsconf.io mailbox (used for POP3/SMTP in Gmail)"
}
