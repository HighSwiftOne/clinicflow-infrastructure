# ====================================================================
# PHASE 16: THE AUDIT INVESTIGATOR (AMAZON ATHENA)
# ====================================================================

# ============================================
# S3 BUCKET FOR ATHENA QUERY RESULTS
# ============================================
resource "aws_s3_bucket" "athena_results" {
  bucket        = "clinicflow-athena-query-results-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = {
    Name        = "ClinicFlow-Athena-Results"
    Environment = "Production"
    HIPAA       = "AuditLogs"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.clinicflow_cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket policy to enforce encryption and deny unencrypted uploads
resource "aws_s3_bucket_policy" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  policy = data.aws_iam_policy_document.athena_results_bucket_policy.json
}

data "aws_iam_policy_document" "athena_results_bucket_policy" {
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.athena_results.arn,
      "${aws_s3_bucket.athena_results.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ============================================
# ATHENA WORKGROUP
# ============================================
resource "aws_athena_workgroup" "auditors" {
  name = "clinicflow-auditors"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.clinicflow_cmk.arn
      }
    }
  }

  tags = {
    Environment = "Production"
    Service     = "Athena"
  }
}

# ============================================
# ATHENA DATABASE (Container for CloudTrail Logs)
# ============================================
resource "aws_athena_database" "audit_logs" {
  name          = "clinicflow_audit_logs"
  bucket        = aws_s3_bucket.athena_results.id
  force_destroy = false

  encryption_configuration {
    encryption_option = "SSE_KMS"
    kms_key           = aws_kms_key.clinicflow_cmk.arn
  }
}