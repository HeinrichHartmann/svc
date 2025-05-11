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