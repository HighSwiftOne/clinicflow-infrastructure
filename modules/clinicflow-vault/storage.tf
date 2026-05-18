# checkov:skip=CKV_AWS_18: "Architecture - This is the central logging bucket; logging it would create an infinite loop."
# checkov:skip=CKV_AWS_145: "FinOps - Bucket contains system logs, not PHI. Default AES256 encryption is sufficient."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication for system logs is cost-prohibitive for the baseline."
# checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are not required for system access logs."
resource "aws_s3_bucket" "clinicflow_logs" {
  bucket        = "clinicflow-logs-clinicflow-core-541495491866"
  force_destroy = true

  tags = {
    Environment = "Production"
    Name        = "ClinicFlow-Core-Access-Logs"
  }
}

resource "aws_s3_bucket_versioning" "clinicflow_logs_versioning" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "clinicflow_logs_block" {
  bucket                  = aws_s3_bucket.clinicflow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clinicflow_logs_encryption" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "clinicflow_logs_policy" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowALBLogging"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::127311923021:root" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.clinicflow_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "clinicflow_logs_lifecycle" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  rule {
    id     = "auto-delete-failed-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}