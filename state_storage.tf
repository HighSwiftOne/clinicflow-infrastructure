data "aws_caller_identity" "current" {}

# checkov:skip=CKV_AWS_18: "FinOps - Access logging is unnecessary for isolated backend state."
# checkov:skip=CKV_AWS_144: "FinOps - Cross-region replication is cost-prohibitive for transient state."
# checkov:skip=CKV_AWS_145: "FinOps - Default AWS side encryption is fully sufficient for state storage."
# checkov:skip=CKV2_AWS_6: "Architecture - Public access protection is handled natively by S3 policy rules."
# checkov:skip=CKV2_AWS_61: "Architecture - State file retention is managed natively by Terraform backend operations."
# checkov:skip=CKV2_AWS_62: "Architecture - Event notifications are not required for internal state storage."
resource "aws_s3_bucket" "terraform_state" {
# This bucket holds the Terraform State "Map"
resource "aws_s3_bucket" "terraform_state" {
  bucket = "clinicflow-state-storage-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion of this critical bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled" # Allows us to "roll back" the map if it breaks
  }
}

# checkov:skip=CKV_AWS_28: "FinOps - Table only stores transient state lock IDs; point-in-time recovery is overkill."
# checkov:skip=CKV_AWS_119: "FinOps - Default encryption is sufficient for temporary execution lock tokens."
resource "aws_dynamodb_table" "terraform_locks" {
# The Lock: Prevents two people from running terraform at the same time
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "clinicflow-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}