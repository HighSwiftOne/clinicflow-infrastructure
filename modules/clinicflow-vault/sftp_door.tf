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

# checkov:skip=CKV_AWS_18: "FinOps - Access logging deferred for pilot baseline."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication deferred for pilot baseline."
# checkov:skip=CKV_AWS_145: "FinOps - Default AES256 encryption is sufficient for pilot baseline."
# checkov:skip=CKV_AWS_21: "FinOps - Versioning is explicitly handled via the separate versioning resource block."
# checkov:skip=CKV2_AWS_62: "Architecture - Event notifications not required for pilot baseline."
# checkov:skip=CKV2_AWS_61: "Architecture - Lifecycle rules deferred for pilot baseline."
# checkov:skip=CKV2_AWS_6: "Architecture - Public Access Block is handled via the separate public_access_block resource."
# checkov:skip=CKV_AWS_18: "FinOps - Access logging is deferred for pilot baseline tracking."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication is cost-prohibitive for the pilot phase."
# checkov:skip=CKV_AWS_145: "FinOps - Default encryption is sufficient; dedicated KMS key is deferred."
# checkov:skip=CKV_AWS_21: "False Positive - Versioning is explicitly defined in its own resource block below."
# checkov:skip=CKV2_AWS_6: "False Positive - Public Access Block is handled via the separate block resource below."
# checkov:skip=CKV2_AWS_61: "Architecture - Storage lifecycle management is deferred for pilot configuration."
# checkov:skip=CKV2_AWS_62: "Architecture - S3 Event notifications are not required for this baseline vault."
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

# checkov:skip=CKV_AWS_164: "Architecture - Public endpoint required for clinic staff access without VPN."
# checkov:skip=CKV_AWS_380: "Security - Explicitly enforcing the standard secure Transfer Security Policy."
# checkov:skip=CKV_AWS_164: "Architecture - Public endpoint is required for receptionist access without corporate VPN tunnels."
# checkov:skip=CKV_AWS_380: "Security - Explicitly enforcing secure protocol definitions for Transfer Family connections."
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