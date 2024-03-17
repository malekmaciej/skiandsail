resource "aws_s3_bucket" "civetta2024" {
  bucket = "civetta2024.skiandsail.org"
  tags   = var.tags
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.civetta2024.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.civetta2024.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.civetta2024.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowGetObjects"
    Statement = [
      {
        Sid       = "AllowPublic"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.civetta2024.arn}/*"
      }
    ]
  })
}

# SSL Certificate in ACM
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  domain_name         = "skiandsail.org"
  zone_id             = var.zone_id
  validation_method   = "DNS"
  wait_for_validation = true
  subject_alternative_names = [
    "*.skiandsail.org"
  ]
  tags = var.tags
  providers = {
    aws = aws.us-east-1
  }
}

#CloudFront

# module "cdn" {
#   source = "terraform-aws-modules/cloudfront/aws"

#   aliases = [var.civetta2024_domain]

#   comment             = "SkiAndSail-Civetta2024"
#   enabled             = true
#   price_class         = "PriceClass_100"
#   retain_on_delete    = false
#   wait_for_deployment = false

#   create_origin_access_identity = true
#   origin_access_identities = {
#     s3_bucket_one = aws_s3_bucket.civetta2024.bucket
#   }

#   origin = {
#     something = {
#       domain_name = local.s3_domain_name_civetta2024_domain
#       custom_origin_config = {
#         http_port              = 80
#         https_port             = 443
#         origin_protocol_policy = "match-viewer"
#         origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
#       }
#     }

#     s3_one = {
#       domain_name = local.s3_domain_name_civetta2024_domain
#       s3_origin_config = {
#         origin_access_identity = "s3_bucket_one"
#       }
#     }
#   }

#   default_cache_behavior = {
#     target_origin_id           = "something"
#     viewer_protocol_policy     = "allow-all"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD"]
#     compress        = true
#     query_string    = true
#   }

#   viewer_certificate = {
#     acm_certificate_arn = module.acm.acm_certificate_arn
#     ssl_support_method  = "sni-only"
#   }
# }

resource "aws_cloudfront_distribution" "this" {

  enabled = true
  aliases = [var.civetta2024_domain]

  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = local.s3_domain_name_civetta2024_domain
    origin_id           = local.s3_origin_id_civetta2024_domain
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {

    target_origin_id = local.s3_origin_id_civetta2024_domain
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  price_class = "PriceClass_100"

}

resource "aws_route53_record" "dns_name_civetta2024" {
  zone_id = var.zone_id
  name    = var.civetta2024_domain
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.this.domain_name]
}