# ------------------------------------------------------------------------------
# REMOTE STATE ANCHOR
# Locks infrastructure state to AWS S3 and DynamoDB
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {
    # Replace this with your exact bucket name from your state logs
    bucket = "clinicflow-state-storage-541495491866"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"

    # Replace this with your exact DynamoDB table name
    dynamodb_table = "clinicflow-state-locks"
    encrypt        = true
  }
}