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

resource "aws_ses_domain_identity" "mail_subdomain" {
  domain = "mail.${local.hh_domain}"
}

resource "aws_route53_record" "ses_verification_mail" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "_amazonses.mail.${local.hh_domain}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.mail_subdomain.verification_token]
}

resource "aws_s3_bucket" "ses_mail_email_storage" {
  bucket = "mail-${local.hh_domain}-email-storage"
}

resource "aws_ses_receipt_rule_set" "mail_rule_set" {
  rule_set_name = "mail_rule_set"
}

resource "aws_ses_receipt_rule" "mail_rule" {
  rule_set_name = aws_ses_receipt_rule_set.mail_rule_set.rule_set_name
  name          = "mail_rule"
  enabled       = true

  recipients = ["mail.${local.hh_domain}"]

  s3_action {
    position         = 1
    bucket_name      = aws_s3_bucket.ses_mail_email_storage.bucket
    object_key_prefix = "emails/"
  }
}

resource "aws_route53_record" "mx_record_mail" {
  zone_id = aws_route53_zone.hh_zone.zone_id
  name    = "mail.${local.hh_domain}"
  type    = "MX"
  ttl     = 300
  records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
} 