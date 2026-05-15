# =========================================================
# 1. Package the Python script into a ZIP file
# =========================================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/heal_s3.py"
  output_path = "${path.module}/functions/heal_s3.zip"
}

# =========================================================
# 2. Give the script permission to modify S3 buckets & VPC
# =========================================================
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

resource "aws_iam_role_policy" "lambda_healer_policy" {
  name = "ClinicFlow-S3-Healer-Policy"
  role = aws_iam_role.lambda_healer_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowS3Discovery",
        Effect   = "Allow",
        Action   = [
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets"
        ],
        Resource = "*" 
      },
      {
        Sid      = "AllowS3Remediation",
        Effect   = "Allow",
        Action   = [
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock"
        ],
        Resource = "arn:aws:s3:::*"
      },
      {
        Sid      = "AllowLogging",
        Effect   = "Allow",
        Action   = ["logs:*"],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid      = "AllowVPCAccess",
        Effect   = "Allow",
        Action   = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

# =========================================================
# 3. Create the actual Serverless Function
# =========================================================
resource "aws_lambda_function" "s3_healer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ClinicFlow-S3-Healer"
  role             = aws_iam_role.lambda_healer_role.arn
  handler          = "heal_s3.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 
  runtime          = "python3.10"
  memory_size      = 128
  timeout          = 15

  # The Invisible Bastion Connection
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.healer_sg.id]
  }

  # Force Terraform to wait for IAM permissions to propagate
  depends_on = [aws_iam_role_policy.lambda_healer_policy]
}

# =========================================================
# 4. The Tripwire (EventBridge)
# =========================================================
resource "aws_cloudwatch_event_rule" "s3_exposure_detector" {
  name        = "clinicflow-s3-exposure-detector"
  description = "Trigger Lambda when S3 Public Access Block is modified"

  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail_type = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["s3.amazonaws.com"],
      eventName   = [
        "PutBucketPublicAccessBlock", 
        "DeleteBucketPublicAccessBlock", 
        "PutBucketAcl", 
        "PutBucketPolicy"
      ]
    }
  })
}

# =========================================================
# 5. Connect the Tripwire to the Python Script
# =========================================================
resource "aws_cloudwatch_event_target" "trigger_healer" {
  rule      = aws_cloudwatch_event_rule.s3_exposure_detector.name 
  target_id = "TriggerHealer"
  arn       = aws_lambda_function.s3_healer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_healer.function_name
  principal     = "events.amazonaws.com"
}

# =========================================================
# 6. AWS CLOUDTRAIL AUDIT LOGGING
# =========================================================
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket_prefix = "clinicflow-audit-"
  force_destroy = true
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
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "audit_trail" {
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
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  target_bucket = aws_s3_bucket.clinicflow_logs.id
  target_prefix = "cloudtrail-access-logs/"
}