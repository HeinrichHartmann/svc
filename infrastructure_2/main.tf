terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    checkly = {
      source  = "checkly/checkly"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "checkly" {
  account_id = var.checkly_account_id
}

variable "checkly_account_id" {
  description = "Checkly account ID"
  type        = string
}
