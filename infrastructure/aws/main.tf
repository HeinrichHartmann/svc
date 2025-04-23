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

resource "aws_route53_zone" "hhnet" {
  name    = "heinrichhartmann.net"
  comment = "local infrastructure"
}


resource "aws_route53_record" "gw" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "gw.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.1",
  ]
  ttl = 300
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.100.120.89",
  ]
  ttl = 300
}

resource "aws_route53_record" "lan" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.lan.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.12",
  ]
  ttl = 300
}

resource "aws_route53_record" "samba_lan" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "smb.lan.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.13",
  ]
  ttl = 300
}

resource "aws_route53_record" "otelcol_pve" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "otel-collector.pve.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.3.3",
  ]
  ttl = 300
}

resource "aws_route53_record" "tailscale" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.100.120.89",
  ]
  ttl = 300
}

resource "aws_route53_record" "hifipi" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.hifipi.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.97.166.55",
  ]
  ttl = 300
}

locals {
    ts_hosts = {
        "pve" = "100.100.120.89"
        "hifipi" = "100.97.166.55"
        "hhe15" = "100.121.201.109"
        "spohrhp20" = "100.67.92.4"
    }
}

resource "aws_route53_record" "ts_hosts" {
  for_each = local.ts_hosts
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "${each.key}.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    each.value,
  ]
  ttl = 300
}

resource "aws_route53_record" "ts_wildcards" {
  for_each = local.ts_hosts
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.${each.key}.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    each.value,
  ]
  ttl = 300
}

#
# Lenas Staudengarten
#

locals {
  ls_domain = "lenas-staudengarten.de"
  ls_bucketname = "lenas-staudengarten.de"
  ls_origin = aws_s3_bucket_website_configuration.ls_bucket.website_endpoint
}

resource "aws_s3_bucket" ls_bucket {
  bucket = local.ls_bucketname
}

resource aws_s3_bucket_acl ls_bucket {
  bucket = aws_s3_bucket.ls_bucket.id
  acl = "private"
}

resource aws_s3_bucket_policy ls_bucket {
  bucket = aws_s3_bucket.ls_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.ls_bucketname}/*"
    }
  ]
}
POLICY
}

resource aws_s3_bucket_public_access_block ls_bucket {
  bucket = aws_s3_bucket.ls_bucket.id
  ignore_public_acls = false
  block_public_acls = false
  block_public_policy = false
  restrict_public_buckets = false
}

resource aws_s3_bucket_website_configuration ls_bucket {
  bucket = aws_s3_bucket.ls_bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource aws_route53_zone ls_zone {
  name = local.ls_domain
}

# CNAME record for verification
resource "aws_route53_record" "verification_record" {
  zone_id = aws_route53_zone.ls_zone.id
  name    = "yfkppn77sxl7y8xzn2cd"
  type    = "CNAME"
  ttl     = 300
  records = ["verify.squarespace.com"]
}

# CNAME record for www
resource "aws_route53_record" "www_record" {
  zone_id = aws_route53_zone.ls_zone.id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["ext-cust.squarespace.com"]
}

# A records
resource "aws_route53_record" "a_record_1" {
  zone_id = aws_route53_zone.ls_zone.id
  name    = ""
  type    = "A"
  ttl     = 300
  records = ["198.185.159.144", "198.185.159.145", "198.49.23.144", "198.49.23.145" ]
}
