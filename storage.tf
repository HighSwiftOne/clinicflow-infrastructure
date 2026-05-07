# --- S3 Bucket for Access Logs ---
resource "aws_s3_bucket" "clinicflow_logs" {
  # Dynamically names the bucket for each client (forces lowercase for S3 rules)
  bucket        = "clinicflow-logs-${lower(var.client_name)}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${var.client_name}-Access-Logs"
    Environment = var.environment
  }
}

# --- Encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "clinicflow_logs_encryption" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Versioning ---
resource "aws_s3_bucket_versioning" "clinicflow_logs_versioning" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Public Access Block ---
resource "aws_s3_bucket_public_access_block" "clinicflow_logs_block" {
  bucket                  = aws_s3_bucket.clinicflow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Lifecycle Configuration ---
resource "aws_s3_bucket_lifecycle_configuration" "clinicflow_logs_lifecycle" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  rule {
    id     = "auto-delete-failed-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --- Bucket Policy (The Handshake) ---
resource "aws_s3_bucket_policy" "clinicflow_logs_policy" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # This is the dedicated AWS account ID for the ELB service in us-east-1
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.clinicflow_logs.arn}/*"
      }
    ]
  })
}