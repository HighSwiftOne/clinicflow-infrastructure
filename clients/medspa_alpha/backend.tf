terraform {
  backend "s3" {
    bucket         = "clinicflow-state-vault-541495491866"
    key            = "clients/medspa_alpha/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "clinicflow-state-lock"
    encrypt        = true
  }
}
