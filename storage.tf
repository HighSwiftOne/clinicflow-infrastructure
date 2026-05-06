data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "clinicflow_logs" {
  # checkov:skip=CKV_AWS_144:FinOps - Cross-Region Replication doubles storage costs.
  # checkov:skip=CKV2_AWS_62:FinOps - Event notifications not required for baseline.
  # checkov:skip=CKV_AWS_18:Architecture - This is the primary log bucket, we do not need recursive logging.
  bucket        = "clinicflow-access-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true 
  
  tags = {
    Name = "ClinicFlow-Access-Logs"
  }
}

resource "aws_s3_bucket_versioning" "clinicflow_logs_versioning" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clinicflow_logs_encryption" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.clinicflow_db_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "clinicflow_logs_block" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "clinicflow_logs_lifecycle" {
  bucket = aws_s3_bucket.clinicflow_logs.id

  rule {
    id     = "auto-delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "clinicflow_logs_policy" {
  bucket = aws_s3_bucket.clinicflow_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBAccessLogs"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.clinicflow_logs.arn}/*"
      },
      {
        Sid    = "AllowVPCFlowLogs"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.clinicflow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AclCheckVPCFlowLogs"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.clinicflow_logs.arn
      }
    ]
  })
}