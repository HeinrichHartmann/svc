terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Certificates are managed in us-east-1. Register additional provider:
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
