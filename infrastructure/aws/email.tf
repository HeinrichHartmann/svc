# Migadu Email Infrastructure for signalsconf.io
#
# Requires environment variables:
#   MIGADU_USERNAME - Your Migadu admin email
#   MIGADU_TOKEN - Migadu API token (from ~/box/secrets/migadu.key)

# Mailboxes
# Gmail will poll these mailboxes via POP3/IMAP

# Main mailbox for signalsconf.io
# Gmail setup (manual):
#   - Add account in Gmail: Settings → Accounts → Add mail account
#   - POP3 Server: pop.migadu.com:995 (SSL)
#   - Username: heinrich@signalsconf.io
#   - Password: (use var.signals_heinrich_password)
#   - Enable "Delete mail from server after retrieval"
#
# Send mail as (manual):
#   - Gmail → Settings → Accounts → Send mail as
#   - SMTP: smtp.migadu.com:465 (SSL) or :587 (STARTTLS)
#   - Username: heinrich@signalsconf.io
#   - Password: (use var.signals_heinrich_password)

resource "migadu_mailbox" "signals_heinrich" {
  name        = "Heinrich Hartmann"
  domain_name = "signalsconf.io"
  local_part  = "heinrich"
  password    = var.signals_heinrich_password

  # Enable all mailbox permissions
  may_send                = true
  may_receive             = true
  may_access_imap         = true
  may_access_pop3         = true
  may_access_manage_sieve = true
}

# Aliases for signalsconf.io
# All forward to the heinrich@signalsconf.io mailbox (which Gmail polls)

locals {
  # List of aliases that forward to heinrich@signalsconf.io
  heinrich_aliases = toset([
    "chair",
    "info",
    "contact",
    "abuse",
    "admin",
    "postmaster",
  ])
}

resource "migadu_alias" "signals_heinrich_aliases" {
  for_each = local.heinrich_aliases

  domain_name  = "signalsconf.io"
  local_part   = each.key
  destinations = [
    "heinrich@signalsconf.io"
  ]
}

# Catch-all alias (optional - forwards any unmatched email to main mailbox)
# resource "migadu_alias" "signals_catchall" {
#   domain_name = "signalsconf.io"
#   local_part  = "*"
#   recipients  = [
#     "heinrich@signalsconf.io"
#   ]
# }
