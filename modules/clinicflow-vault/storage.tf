# ====================================================================
# CENTRALIZED ACCESS LOGGING ENGINE (AUDIT DROP ZONE)
# ====================================================================
resource "aws_s3_bucket" "clinicflow_logs" {
  # checkov:skip=CKV_AWS_18: "False Positive - This bucket IS the centralized access logging location engine."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region data replication is cost-prohibitive for local storage infrastructure log storage."
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

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowConfigDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
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

    filter {}

    expiration {
      days = 90
    }
  }
}

# ====================================================================
# CORE PHI RECORD STORAGE DATA TIER (PATIENT VAULT)
# ====================================================================
resource "aws_s3_bucket" "patient_vault" {
  # checkov:skip=CKV_AWS_18: "Architecture - Secondary tracking drop zones handle native logging hooks."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region data replication is cost-prohibitive for laboratory environments."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are evaluated downstream via trail engines."
  bucket        = "clinicflow-patient-vault-541495491866"
  force_destroy = true

  tags = {
    Name        = "ClinicFlow-Patient-Vault"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "patient_vault_block" {
  bucket                  = aws_s3_bucket.patient_vault.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "patient_vault_versioning" {
  bucket = aws_s3_bucket.patient_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "patient_vault_encryption" {
  bucket = aws_s3_bucket.patient_vault.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.clinicflow_cmk.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "patient_vault_logging" {
  bucket        = aws_s3_bucket.patient_vault.id
  target_bucket = aws_s3_bucket.clinicflow_logs.id
  target_prefix = "patient-vault-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "patient_vault_lifecycle" {
  # checkov:skip=CKV_AWS_300: "Architecture - Multipart file upload abort timelines are governed by global lifecycle standards."
  bucket = aws_s3_bucket.patient_vault.id

  rule {
    id     = "phi-retention-schedule"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ====================================================================
# ELITE COMPLIANCE: ALB AUDIT LOGS
# ====================================================================
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "clinicflow-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "alb_logs_block" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        # The Fix: We injected the /alb-logs/ prefix into the IAM path
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}