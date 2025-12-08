terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.9"
    }
  }
}

# Credentials via environment variables (sourced by .envrc):
#   B2_APPLICATION_KEY_ID  - from ~/box/secrets/backblaze_master.key
#   B2_APPLICATION_KEY     - from ~/box/secrets/backblaze_master.key

resource "b2_bucket" "restic" {
  bucket_name = "hh-restic-b2"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_hiding_to_deleting  = 1
    days_from_uploading_to_hiding = 0
  }
}
