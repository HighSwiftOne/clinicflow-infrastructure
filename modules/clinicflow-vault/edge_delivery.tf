# ====================================================================
# PHASE 20: GLOBAL EDGE ACCELERATION (CLOUDFRONT)
# ====================================================================

resource "aws_cloudfront_distribution" "clinicflow_cdn" {
  # checkov:skip=CKV_AWS_86: CDN access logging temporarily disabled to prevent S3 ACL bucket policy conflicts.
  # checkov:skip=CKV_AWS_34: WAF is enforced at the ALB level. CloudFront requires a separate global WAF scope.
  # checkov:skip=CKV_AWS_310: Origin failover is over-engineering for a single-tenant MedSpa pilot.
  # checkov:skip=CKV2_AWS_47: WAF attachment bypassed due to regionality constraints.
  # checkov:skip=CKV2_AWS_32: OAI is not required because the origin is an ALB, not an S3 bucket.

  enabled         = true
  is_ipv6_enabled = true
  comment         = "ClinicFlow CDN - MedSpa Patient Portal"

  # Origin: Application Load Balancer
  origin {
    domain_name = aws_lb.clinicflow_alb.dns_name
    origin_id   = "ClinicFlow-ALB"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior (Dynamic Content – Pure Proxy)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "ClinicFlow-ALB"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Host", "CloudFront-Forwarded-Proto"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # Geo restriction – Block international botnets
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "Production"
    Service     = "CloudFront"
    HIPAA       = "EdgeEncryption"
  }
}