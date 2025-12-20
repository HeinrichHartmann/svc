terraform {
  required_providers {
    checkly = {
      source  = "checkly/checkly"
      version = "~> 1.0"
    }
  }
}

provider "checkly" {
  account_id = var.checkly_account_id
}

variable "checkly_account_id" {
  description = "Checkly account ID"
  type        = string
}
