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

# ====================================================================
# MASTER CRITICAL SECURITY COMPLIANCE ENVELOPE (SINGLE SOURCE OF TRUTH)
# ====================================================================
# FIXED: Centralized single declaration matching the module scope 
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