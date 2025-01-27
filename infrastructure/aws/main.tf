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


#
# HeinrichHartmann.com
#


locals {
  hh_domain = "heinrichhartmann.com"
  hh_bucketname = "heinrichhartmann.com"
  hh_origin = aws_s3_bucket_website_configuration.hh_bucket.website_endpoint
}

resource "aws_s3_bucket" hh_bucket {
  bucket = local.hh_bucketname
}

resource aws_s3_bucket_acl hh_bucket {
  bucket = aws_s3_bucket.hh_bucket.id
  acl = "private"
}

resource aws_s3_bucket_policy hh_bucket {
  bucket = aws_s3_bucket.hh_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.hh_bucketname}/*"
    }
  ]
}
POLICY
}

resource aws_s3_bucket_public_access_block hh_bucket {
  bucket = aws_s3_bucket.hh_bucket.id
  ignore_public_acls = false
  block_public_acls = false
  block_public_policy = false
  restrict_public_buckets = false
}

resource aws_s3_bucket_website_configuration hh_bucket {
  bucket = aws_s3_bucket.hh_bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource aws_route53_zone hh_zone {
  name = local.hh_domain
}

resource aws_acm_certificate hh_certificate {
  provider = aws.us-east-1
  domain_name = local.hh_domain
  subject_alternative_names = [ format("www.%s", local.hh_domain), format("*.%s", local.hh_domain) ]
  validation_method = "DNS"
}

resource aws_cloudfront_distribution hh_distribution {
  enabled = true
  aliases = [ local.hh_domain, format("www.%s", local.hh_domain) ]
  is_ipv6_enabled = true
  price_class = "PriceClass_100"
  origin {
    domain_name = local.hh_origin
    origin_id = local.hh_origin
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.hh_origin
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    min_ttl          = "0"
    default_ttl      = "300"
    max_ttl          = "1200"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.hh_certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource aws_route53_record hh_cdn_root {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = local.hh_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.hh_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.hh_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource aws_route53_record hh_cdn_root_www {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "www.${local.hh_domain}"
  type = "CNAME"
  records = [ local.hh_domain ]
  ttl = 300
}
