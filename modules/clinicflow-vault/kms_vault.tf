# ====================================================================
# CENTRAL ENTERPRISE COMPLIANCE CRYPTOGRAPHIC VAULT
# ====================================================================
resource "aws_kms_key" "clinicflow_cmk" {
  description             = "Master Single-Tenant Compliance Key for ClinicFlow ePHI Assets"
  deletion_window_in_days = 30
  enable_key_rotation     = true # Mandatory compliance check loop

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootManagement"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::541495491866:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogsEncryption"
        Effect    = "Allow"
        Principal = { Service = "logs.us-east-1.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "ClinicFlow-Core-CMK"
    Environment = "Production"
  }
}

resource "aws_kms_alias" "clinicflow_cmk_alias" {
  name          = "alias/clinicflow-core-key"
  target_key_id = aws_kms_key.clinicflow_cmk.key_id
}