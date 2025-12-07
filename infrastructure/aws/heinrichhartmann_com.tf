locals {
  hh_domain = "heinrichhartmann.com"
  hh_bucketname = "heinrichhartmann.com"
  hh_origin = aws_s3_bucket_website_configuration.hh_bucket.website_endpoint

  # Mailbox password (read directly from secrets)
  hh_mailbox_password = trimspace(file(pathexpand("~/box/secrets/migadu_heinrich_hh.pass")))

  # Email aliases that forward to heinrich@heinrichhartmann.com
  hh_heinrich_aliases = toset([
    "abuse",
    "admin",
    "apple",
    "consulting",
    "info",
    "postmaster",
  ])
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

# =============================================================================
# Migadu Email Configuration
# =============================================================================

# Verification TXT Record
resource "aws_route53_record" "hh_migadu_verify" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = local.hh_domain
  type    = "TXT"
  ttl     = 3600
  records = [
    "hosted-email-verify=nqp0aks6",
    "v=spf1 include:spf.migadu.com -all",
  ]
}

# MX Records
resource "aws_route53_record" "hh_mx" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = local.hh_domain
  type    = "MX"
  ttl     = 3600
  records = [
    "10 aspmx1.migadu.com",
    "20 aspmx2.migadu.com",
  ]
}

# DKIM Records (3 rotating keys)
resource "aws_route53_record" "hh_dkim_1" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "key1._domainkey.${local.hh_domain}"
  type    = "CNAME"
  ttl     = 3600
  records = ["key1.${local.hh_domain}._domainkey.migadu.com."]
}

resource "aws_route53_record" "hh_dkim_2" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "key2._domainkey.${local.hh_domain}"
  type    = "CNAME"
  ttl     = 3600
  records = ["key2.${local.hh_domain}._domainkey.migadu.com."]
}

resource "aws_route53_record" "hh_dkim_3" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "key3._domainkey.${local.hh_domain}"
  type    = "CNAME"
  ttl     = 3600
  records = ["key3.${local.hh_domain}._domainkey.migadu.com."]
}

# Migadu Mailbox
resource "migadu_mailbox" "hh_heinrich" {
  name        = "Heinrich Hartmann"
  domain_name = local.hh_domain
  local_part  = "heinrich"
  password    = local.hh_mailbox_password

  may_send                = true
  may_receive             = true
  may_access_imap         = true
  may_access_pop3         = true
  may_access_manage_sieve = true
}

# Aliases
resource "migadu_alias" "hh_heinrich_aliases" {
  for_each = local.hh_heinrich_aliases

  domain_name  = local.hh_domain
  local_part   = each.key
  destinations = ["heinrich@${local.hh_domain}"]
} 