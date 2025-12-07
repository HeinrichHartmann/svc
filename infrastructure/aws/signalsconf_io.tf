locals {
  sc_domain     = "signalsconf.io"
  sc_bucketname = "signalsconf.io"
  sc_origin     = aws_s3_bucket_website_configuration.sc_bucket.website_endpoint

  # Email aliases that forward to heinrich@signalsconf.io
  sc_heinrich_aliases = toset([
    "chair",
    "info",
    "contact",
    "abuse",
    "admin",
    "postmaster",
  ])
}

# S3 Bucket for static website hosting
resource "aws_s3_bucket" "sc_bucket" {
  bucket = local.sc_bucketname
}

# Note: ACL resource removed - bucket uses BucketOwnerEnforced ownership which disables ACLs

# Bucket policy allowing public read access
resource "aws_s3_bucket_policy" "sc_bucket" {
  depends_on = [aws_s3_bucket_public_access_block.sc_bucket]
  bucket     = aws_s3_bucket.sc_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${local.sc_bucketname}/*"
      }
    ]
  })
}

# Public access block configuration
resource "aws_s3_bucket_public_access_block" "sc_bucket" {
  bucket                  = aws_s3_bucket.sc_bucket.id
  ignore_public_acls      = false
  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "sc_bucket" {
  bucket = aws_s3_bucket.sc_bucket.id
  index_document {
    suffix = "index.html"
  }
}

# Route53 hosted zone (imported from existing)
resource "aws_route53_zone" "sc_zone" {
  name = local.sc_domain
}

# ACM Certificate for HTTPS (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "sc_certificate" {
  provider                  = aws.us-east-1
  domain_name              = local.sc_domain
  subject_alternative_names = ["www.${local.sc_domain}", "*.${local.sc_domain}"]
  validation_method        = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "sc_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sc_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.sc_zone.zone_id
}

# Certificate validation waiter
resource "aws_acm_certificate_validation" "sc_certificate" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.sc_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.sc_cert_validation : record.fqdn]
}

# CloudFront distribution with HTTPS
resource "aws_cloudfront_distribution" "sc_distribution" {
  depends_on = [aws_acm_certificate_validation.sc_certificate]

  enabled             = true
  aliases             = [local.sc_domain, "www.${local.sc_domain}"]
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  origin {
    domain_name = local.sc_origin
    origin_id   = local.sc_origin
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.sc_origin
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200

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
    acm_certificate_arn      = aws_acm_certificate.sc_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Route53 A record pointing to CloudFront (not S3)
resource "aws_route53_record" "sc_root" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = local.sc_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.sc_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.sc_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# www CNAME record pointing to root domain
resource "aws_route53_record" "sc_www" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "www.${local.sc_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [local.sc_domain]
}

# ========================================
# Migadu Email DNS Records
# ========================================

# TXT Records (Verification + SPF combined)
resource "aws_route53_record" "sc_txt" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = local.sc_domain
  type    = "TXT"
  ttl     = 300
  records = [
    "hosted-email-verify=mz3g2xgk",    # Migadu verification
    "v=spf1 include:spf.migadu.com -all" # SPF policy
  ]
}

# MX Records (mail exchange)
resource "aws_route53_record" "sc_mx" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = local.sc_domain
  type    = "MX"
  ttl     = 300
  records = [
    "10 aspmx1.migadu.com",
    "20 aspmx2.migadu.com"
  ]
}

# DKIM Keys (3 keys for rotation)
resource "aws_route53_record" "sc_dkim_key1" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "key1._domainkey.${local.sc_domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["key1.${local.sc_domain}._domainkey.migadu.com."]
}

resource "aws_route53_record" "sc_dkim_key2" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "key2._domainkey.${local.sc_domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["key2.${local.sc_domain}._domainkey.migadu.com."]
}

resource "aws_route53_record" "sc_dkim_key3" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "key3._domainkey.${local.sc_domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["key3.${local.sc_domain}._domainkey.migadu.com."]
}

# DMARC Record (Domain-based Message Authentication)
resource "aws_route53_record" "sc_dmarc" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "_dmarc.${local.sc_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine;"]
}

# Autoconfig for Thunderbird (optional but helpful)
resource "aws_route53_record" "sc_autoconfig" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "autoconfig.${local.sc_domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["autoconfig.migadu.com."]
}

# SRV Records for autodiscovery (optional but helpful)
resource "aws_route53_record" "sc_autodiscover" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "_autodiscover._tcp.${local.sc_domain}"
  type    = "SRV"
  ttl     = 300
  records = ["0 1 443 autodiscover.migadu.com"]
}

resource "aws_route53_record" "sc_submissions" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "_submissions._tcp.${local.sc_domain}"
  type    = "SRV"
  ttl     = 300
  records = ["0 1 465 smtp.migadu.com"]
}

resource "aws_route53_record" "sc_imaps" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "_imaps._tcp.${local.sc_domain}"
  type    = "SRV"
  ttl     = 300
  records = ["0 1 993 imap.migadu.com"]
}

resource "aws_route53_record" "sc_pop3s" {
  zone_id = aws_route53_zone.sc_zone.zone_id
  name    = "_pop3s._tcp.${local.sc_domain}"
  type    = "SRV"
  ttl     = 300
  records = ["0 1 995 pop.migadu.com"]
}

# ========================================
# Migadu Mailboxes & Aliases
# ========================================

# Main mailbox for signalsconf.io
# Gmail setup (manual):
#   - Add account in Gmail: Settings → Accounts → Add mail account
#   - POP3 Server: pop.migadu.com:995 (SSL)
#   - Username: heinrich@signalsconf.io
#   - Password: (from ~/box/secrets/migadu_heinrich.pass)
#
# Send mail as (manual):
#   - Gmail → Settings → Accounts → Send mail as
#   - SMTP: smtp.migadu.com:465 (SSL) or :587 (STARTTLS)
#   - Username: heinrich@signalsconf.io

resource "migadu_mailbox" "signals_heinrich" {
  name        = "Heinrich Hartmann"
  domain_name = local.sc_domain
  local_part  = "heinrich"
  password    = var.signals_heinrich_password

  may_send                = true
  may_receive             = true
  may_access_imap         = true
  may_access_pop3         = true
  may_access_manage_sieve = true
}

# Aliases - all forward to heinrich@signalsconf.io (which Gmail polls)
resource "migadu_alias" "signals_heinrich_aliases" {
  for_each = local.sc_heinrich_aliases

  domain_name  = local.sc_domain
  local_part   = each.key
  destinations = ["heinrich@${local.sc_domain}"]
}
