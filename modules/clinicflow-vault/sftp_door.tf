# ====================================================================
# SECURE COMPLIANCE INGRESS LAYER - SFTP SERVICE GATEWAY
# ====================================================================
resource "aws_transfer_server" "clinicflow_sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_logging_role.arn
  protocols              = ["SFTP"]

  tags = {
    Name        = "ClinicFlow-SFTP-Gateway"
    Environment = "Production"
  }
}

resource "aws_iam_role" "sftp_logging_role" {
  name = "ClinicFlow-SFTP-Logging-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TransferAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sftp_logging_policy" {
  name = "ClinicFlow-SFTP-Logging-Policy"
  role = aws_iam_role.sftp_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ====================================================================
# CLINICAL USER PROVISIONING & IDENTITY POLICIES
# ====================================================================
resource "aws_iam_role" "receptionist_sftp_role" {
  name = "ClinicFlow-Receptionist-SFTP"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TransferUserAssume"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "receptionist_sftp_policy" {
  name = "ClinicFlow-Receptionist-SFTP-Policy"
  role = aws_iam_role.receptionist_sftp_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3HomeDirectoryAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = ["arn:aws:s3:::clinicflow-patient-vault-541495491866"]
      },
      {
        Sid    = "AllowS3ObjectManipulation"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = ["arn:aws:s3:::clinicflow-patient-vault-541495491866/*"]
      },
      {
        Sid    = "AllowKMSCryptographicHandshake"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_transfer_user" "receptionist" {
  server_id      = aws_transfer_server.clinicflow_sftp.id
  user_name      = "clinic-receptionist"
  role           = aws_iam_role.receptionist_sftp_role.arn
  home_directory = "/clinicflow-patient-vault-541495491866/intake-dropzone"
}