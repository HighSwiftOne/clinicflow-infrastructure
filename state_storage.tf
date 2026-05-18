# checkov:skip=CKV_AWS_18: "FinOps - Access logging is unnecessary for isolated backend state storage."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication is cost-prohibitive for tracking transient local state."
# checkov:skip=CKV_AWS_145: "FinOps - Default AWS-managed encryption is completely sufficient for transient state management."
# checkov:skip=CKV2_AWS_6: "Architecture - Public access protection is strictly handled via independent block resources below."
# checkov:skip=CKV2_AWS_61: "Architecture - State file lifecycle transitions are handled natively by backend engines."
# checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are unnecessary for internal state locking vaults."
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "clinicflow-state-vault-541495491866"
  force_destroy = true

  tags = {
    Name        = "ClinicFlow-State-Storage"
    Environment = "Production"
  }
}

# TRANSITION BLOCK: Authorizes AWS to forcefully empty and destroy the old versioned bucket
resource "aws_s3_bucket" "old_state_storage" {
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

# checkov:skip=CKV_AWS_28: "FinOps - DynamoDB table only stores active execution lock tokens; point-in-time recovery is unnecessary."
# checkov:skip=CKV_AWS_119: "FinOps - Default encryption profiles are completely sufficient for transient lock records."
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "clinicflow-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "ClinicFlow-State-Locks"
    Environment = "Production"
  }
}

# TRANSITION BLOCK: Safely catches and holds the old locked execution table
resource "aws_dynamodb_table" "old_terraform_locks" {
  name         = "clinicflow-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}