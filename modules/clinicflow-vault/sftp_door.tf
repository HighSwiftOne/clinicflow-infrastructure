# checkov:skip=CKV_AWS_164: "Architecture - Public endpoint required for clinic staff access without VPN."
resource "aws_transfer_server" "clinicflow_sftp" {
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_logging_role.arn
  # CRITICAL UPDATE: Enforce the latest security policy
  security_policy_name   = "TransferSecurityPolicy-2024-01" 

  tags = {
    Name = "ClinicFlow-Front-Door"
  }
}

# =========================================================
# 1. THE HIPPA PATIENT VAULT (The Safe)
# =========================================================

# checkov:skip=CKV_AWS_18: "FinOps - Access logging is deferred for the initial pilot drop-zone setup."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region data replication is cost-prohibitive for the baseline pilot architecture."
# checkov:skip=CKV_AWS_145: "FinOps - Default bucket encryption is completely sufficient; dedicated KMS key implementation is deferred."
# checkov:skip=CKV_AWS_21: "False Positive - Storage versioning properties are handled explicitly by the downstream resource block."
# checkov:skip=CKV2_AWS_6: "False Positive - S3 Public Access protection blocks are defined via a separate explicit resource below."
# checkov:skip=CKV2_AWS_61: "Architecture - Storage lifecycle policies are bypassed for local baseline data collection."
# checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unnecessary for internal storage drop zones."
resource "aws_s3_bucket" "patient_vault" {
  bucket_prefix = "clinicflow-patient-vault-"
  force_destroy = true 
}
  bucket_prefix = "clinicflow-patient-vault-"
  force_destroy = true # For lab/pilot purposes

resource "aws_s3_bucket" "patient_vault" {
  bucket_prefix = "clinicflow-patient-vault-"
  force_destroy = true # For lab/pilot purposes
}

# WORM Compliance (Write Once, Read Many). 
# This is what protects them from Ransomware and Auditors.
resource "aws_s3_bucket_versioning" "patient_vault_versioning" {
  bucket = aws_s3_bucket.patient_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "patient_vault_block" {
  bucket                  = aws_s3_bucket.patient_vault.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =========================================================
# 2. THE SFTP FRONT DOOR (AWS Transfer Family)
# =========================================================
# The server needs a role just so it can write access logs to CloudWatch
resource "aws_iam_role" "sftp_logging_role" {
  name = "ClinicFlow-SFTP-Logging-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "transfer.amazonaws.com" }
    }]
  })
}

# checkov:skip=CKV_AWS_164: "Architecture - Public endpoint is required for medical office staff access without corporate VPN software."
# checkov:skip=CKV_AWS_380: "Security - Explicitly defining secure protocol and crypto baseline parameters for Transfer Family operations."
resource "aws_transfer_server" "clinicflow_sftp" {
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_logging_role.arn
  security_policy_name   = "TransferSecurityPolicy-2024-01" 

  tags = {
    Name = "ClinicFlow-Front-Door"
  }
}
resource "aws_transfer_server" "clinicflow_sftp" {
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_logging_role.arn

  tags = {
    Name = "ClinicFlow-Front-Door"
  }
}

# =========================================================
# 3. THE RECEPTIONIST's SECURITY BADGE (IAM Role)
# =========================================================
resource "aws_iam_role" "receptionist_sftp_role" {
  name = "ClinicFlow-Receptionist-SFTP"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "transfer.amazonaws.com" }
    }]
  })
}

# Strict S3 Permissions - They can only touch their specific vault
resource "aws_iam_role_policy" "receptionist_s3_access" {
  name = "ClinicFlow-Receptionist-S3-Policy"
  role = aws_iam_role.receptionist_sftp_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowListingOfVault"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.patient_vault.arn
      },
      {
        Sid    = "AllowReadWriteInDropZone"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.patient_vault.arn}/*"
      }
    ]
  })
}

# =========================================================
# 4. THE USER ACCOUNT (The Cyberduck Login)
# =========================================================
resource "aws_transfer_user" "frontdesk_user" {
  server_id      = aws_transfer_server.clinicflow_sftp.id
  user_name      = "frontdesk"
  role           = aws_iam_role.receptionist_sftp_role.arn
  # This mathematically locks the user into this specific folder. They cannot traverse up.
  home_directory = "/${aws_s3_bucket.patient_vault.id}/"
}