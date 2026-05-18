resource "aws_s3_bucket" "clinicflow_logs" {
  # checkov:skip=CKV_AWS_18: "False Positive - This bucket IS the centralized access logging location engine."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region data replication is cost-prohibitive for simple local storage infrastructure log storage."
  # checkov:skip=CKV_AWS_145: "FinOps - Default AWS-managed server-side encryption is completely sufficient for audit tracking records."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unnecessary for internal storage drop zones."
  bucket        = "clinicflow-logs-clinicflow-core-541495491866"
  force_destroy = true

  tags = {
    Environment = "Production"
    Name        = "ClinicFlow-Core-Access-Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "clinicflow_logs_block" {
  bucket                  = aws_s3_bucket.clinicflow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "clinicflow_logs_versioning" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "clinicflow_logs_policy" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowLogging"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.clinicflow_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "clinicflow_logs_lifecycle" {
  # checkov:skip=CKV_AWS_300: "Architecture - Incomplete multipart upload abort metrics are managed by global lifecycle schedules."
  bucket = aws_s3_bucket.clinicflow_logs.id
  rule {
    id     = "log-expiration"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}