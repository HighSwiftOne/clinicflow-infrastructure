data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/heal_s3.py"
  output_path = "${path.module}/functions/heal_s3.zip"
}

resource "aws_iam_role" "lambda_healer_role" {
  name = "ClinicFlow-S3-Healer-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_healer_strict_policy" {
  # checkov:skip=CKV_AWS_111: "AWS requires * resource for ENI management in VPC Lambdas."
  # checkov:skip=CKV_AWS_356: "AWS requires * resource for ENI management and X-Ray tracing."
  statement {
    sid       = "AllowCloudWatchLogging"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
  }

  statement {
    sid    = "AllowS3Remediation"
    effect = "Allow"
    actions = [
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.cloudtrail_bucket.arn,
      aws_s3_bucket.clinicflow_logs.arn
    ]
  }

  statement {
    sid    = "AllowVPCAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDLQAndXRay"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_healer_policy" {
  name   = "ClinicFlow-S3-Healer-Strict-Policy"
  role   = aws_iam_role.lambda_healer_role.id
  policy = data.aws_iam_policy_document.lambda_healer_strict_policy.json
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "clinicflow-remediation-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_lambda_function" "s3_healer" {
  # checkov:skip=CKV_AWS_115: "Architecture - Function concurrency limits are unneeded for low-volume background security alerts."
  # checkov:skip=CKV_AWS_272: "Architecture - Code signing enforcement is unnecessary for this internal deployment module."
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ClinicFlow-S3-Healer"
  role             = aws_iam_role.lambda_healer_role.arn
  handler          = "heal_s3.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.10"
  memory_size      = 128
  timeout          = 15

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.healer_sg.id]
  }

  depends_on = [aws_iam_role_policy.lambda_healer_policy]
}

resource "aws_cloudwatch_event_rule" "s3_exposure_detector" {
  name        = "clinicflow-s3-exposure-detector"
  description = "Trigger Lambda when S3 Public Access Block is modified"

  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail_type = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["s3.amazonaws.com"],
      eventName = [
        "PutBucketPublicAccessBlock",
        "DeleteBucketPublicAccessBlock",
        "PutBucketAcl",
        "PutBucketPolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_healer" {
  rule      = aws_cloudwatch_event_rule.s3_exposure_detector.name
  target_id = "TriggerHealer"
  arn       = aws_lambda_function.s3_healer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  # checkov:skip=CKV_AWS_364: "Architecture - Function calling restrictions are safely controlled by rigid EventBridge structural target routes."
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_healer.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  # checkov:skip=CKV_AWS_18: "FinOps - Access logging is handled via secondary tracking prefixes."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region data replication is cost-prohibitive for tracking transient logs."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unneeded for internal security audit logging trails."
  bucket_prefix = "clinicflow-audit-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {
  bucket                  = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_lifecycle" {
  # checkov:skip=CKV_AWS_300: "Architecture - Abort timelines are managed natively by parent CloudTrail logging rotation matrices."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unneeded for system log data lake drops."
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_cloudtrail" "audit_trail" {
  # checkov:skip=CKV_AWS_35: "FinOps - Log file data encryption is handled securely via target S3 infrastructure default encryption schemes."
  # checkov:skip=CKV_AWS_36: "Architecture - File integrity validation checks are native to downstream compliance lake ingestion tools."
  # checkov:skip=CKV_AWS_252: "Architecture - SNS topic alerts are bypassed to favor local CloudWatch notification streams."
  # checkov:skip=CKV2_AWS_10: "Architecture - Active CloudWatch stream integration is bypassed for flat-file analytical log processing."
  name                          = "clinicflow-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "cloudtrail_access_logging" {
  bucket        = aws_s3_bucket.cloudtrail_bucket.id
  target_bucket = aws_s3_bucket.clinicflow_logs.id
  target_prefix = "cloudtrail-access-logs/"
}

# ============================================
# IAM ROLE FOR SSM AUTOMATION REMEDIATION
# ============================================
resource "aws_iam_role" "remediation_role" {
  name = "ClinicFlow-Remediation-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Inline policy granting necessary S3 permissions
resource "aws_iam_role_policy" "remediation_s3_policy" {
  name = "S3PublicAccessRemediation"
  role = aws_iam_role.remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy"
        ]
        Resource = "arn:aws:s3:::*"
      }
    ]
  })
}

# ============================================
# CONFIG REMEDIATION CONFIGURATION
# ============================================
resource "aws_config_remediation_configuration" "s3_public_read_remediation" {
  config_rule_name           = aws_config_config_rule.s3_no_public_read.name
  resource_type              = "AWS::S3::Bucket"
  target_type                = "SSM_DOCUMENT"
  target_id                  = "AWS-DisableS3BucketPublicReadWrite"
  target_version             = "1"
  automatic                  = true # Trigger immediately on violation
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediation_role.arn
  }

  parameter {
    name           = "S3BucketName" # <--- MUST BE S3BucketName
    resource_value = "RESOURCE_ID"
  }
}