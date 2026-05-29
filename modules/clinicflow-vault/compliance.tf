# ============================================
# DATA SOURCES (No hardcoded IDs)
# ============================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================
# IAM ROLE FOR AWS CONFIG
# ============================================
resource "aws_iam_role" "config_role" {
  name = "ClinicFlow-Config-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Managed policy for Config (minimum required)
resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Custom inline policy to write to your S3 bucket
resource "aws_iam_role_policy" "config_s3" {
  name = "ConfigS3Delivery"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${module.pilot_medspa.aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl"
        ]
        Resource = module.pilot_medspa.aws_s3_bucket.cloudtrail_bucket.arn
      }
    ]
  })
}

# ============================================
# S3 BUCKET POLICY (Allow Config to write)
# ============================================
resource "aws_s3_bucket_policy" "config_delivery" {
  bucket = module.pilot_medspa.aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.config_delivery.json
}

data "aws_iam_policy_document" "config_delivery" {
  statement {
    sid    = "AllowConfigDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.pilot_medspa.aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# ============================================
# CONFIGURATION RECORDER & DELIVERY CHANNEL
# ============================================
resource "aws_config_configuration_recorder" "main" {
  name     = "clinicflow-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true # Track IAM, CloudTrail, etc.
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "clinicflow-delivery-channel"
  s3_bucket_name = module.pilot_medspa.aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix  = "AWSLogs/${data.aws_caller_identity.current.account_id}/Config"

  depends_on = [aws_config_configuration_recorder.main]
}

# Start recording
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# ============================================
# HIPAA MANAGED CONFIG RULES (Top 5 critical)
# ============================================
# 1. RDS storage encryption
resource "aws_config_config_rule" "rds_encrypted" {
  name        = "clinicflow-rds-storage-encrypted"
  description = "Checks whether RDS DB instances are encrypted at rest."

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# 2. S3 bucket public read prohibited
resource "aws_config_config_rule" "s3_no_public_read" {
  name        = "clinicflow-s3-bucket-public-read-prohibited"
  description = "Checks that your S3 buckets do not allow public read access."

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# 3. S3 bucket server-side encryption enabled
resource "aws_config_config_rule" "s3_encryption" {
  name        = "clinicflow-s3-bucket-server-side-encryption-enabled"
  description = "Checks that S3 buckets have server-side encryption enabled."

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# 4. VPC flow logs enabled
resource "aws_config_config_rule" "vpc_flow_logs" {
  name        = "clinicflow-vpc-flow-logs-enabled"
  description = "Checks whether VPC flow logs are enabled for all VPCs."

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# 5. CloudTrail enabled (global)
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name        = "clinicflow-cloudtrail-enabled"
  description = "Checks whether CloudTrail is enabled in the account."

  source {
    owner             = "AWS"
    source_identifier = "CLOUDTRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# ============================================
# (Optional) Remediation – auto-fix S3 public buckets
# ============================================
# Uncomment if you want to auto-remediate S3 public read buckets via a Lambda
# resource "aws_config_remediation_configuration" "s3_public_read" {
#   config_rule_name = aws_config_config_rule.s3_no_public_read.name
#   resource_type    = "AWS::S3::Bucket"
#   target_type      = "SSM_DOCUMENT"
#   target_id        = "AWS-EnableS3BucketEncryption"
#   automatic        = true
#   maximum_automatic_attempts = 5
#   retry_seconds    = 60
# }