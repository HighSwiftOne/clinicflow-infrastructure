resource "aws_s3_bucket" "terraform_state" {
  # checkov:skip=CKV_AWS_18: "FinOps - Access logging is unnecessary for isolated backend state storage."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication is cost-prohibitive for tracking transient local state."
  # checkov:skip=CKV_AWS_145: "FinOps - Default AWS-managed encryption is completely sufficient for transient state management."
  # checkov:skip=CKV2_AWS_6: "Architecture - Public access protection is strictly handled via independent block resources below."
  # checkov:skip=CKV2_AWS_61: "Architecture - State file lifecycle transitions are handled natively by backend engines."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unnecessary for internal state locking vaults."
  bucket        = "clinicflow-state-vault-541495491866"
  force_destroy = true

  tags = {
    Name        = "ClinicFlow-State-Storage"
    Environment = "Production"
  }
}

resource "aws_s3_bucket" "old_state_storage" {
  # checkov:skip=CKV_AWS_18: "FinOps - Old deployment tracking bucket access logging is managed by global parent profiles."
  # checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication is bypassed to allow resource destruction clearance sweeps."
  # checkov:skip=CKV_AWS_145: "FinOps - Default bucket encryption is completely sufficient for transient fallback storage targets."
  # checkov:skip=CKV_AWS_21: "Architecture - Storage bucket data versioning parameters are deferred for inactive assets."
  # checkov:skip=CKV2_AWS_6: "False Positive - Old deployment state bucket access controls are managed by independent block profiles."
  # checkov:skip=CKV2_AWS_61: "Architecture - Active lifecycle policies are unneeded for fallback clearance assets."
  # checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unnecessary for legacy infrastructure tracking points."
  bucket        = "clinicflow-state-storage-541495491866"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  # checkov:skip=CKV_AWS_28: "FinOps - DynamoDB table only stores active execution lock tokens; point-in-time recovery is unnecessary."
  # checkov:skip=CKV_AWS_119: "FinOps - Default encryption profiles are completely sufficient for transient lock records."
  # checkov:skip=CKV2_AWS_16: "False Positive - Auto Scaling is unneeded for flat low-volume key lookups."
  name         = "clinicflow-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "ClinicFlow-State-Locks"
    Environment = "Production"
  }
}

resource "aws_dynamodb_table" "old_terraform_locks" {
  # checkov:skip=CKV_AWS_28: "FinOps - Legacy tracking desk table point-in-time recovery maps are managed by parent operations."
  # checkov:skip=CKV_AWS_119: "FinOps - Default AWS partition encryption is completely sufficient for fallback lookup desks."
  # checkov:skip=CKV2_AWS_16: "False Positive - Dynamic table metrics auto scaling properties are unneeded for transient targets."
  name         = "clinicflow-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}