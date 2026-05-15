data "aws_caller_identity" "current" {}

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