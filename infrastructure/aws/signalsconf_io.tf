locals {
  sc_domain     = "signalsconf.io"
  sc_bucketname = "signalsconf.io"
  sc_origin     = aws_s3_bucket_website_configuration.sc_bucket.website_endpoint
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
