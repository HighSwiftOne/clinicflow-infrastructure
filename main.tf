# ClinicFlow 1.0 - Production Alpha Version

terraform {
  backend "s3" {
    bucket         = "clinicflow-state-storage-541495491866" # The bucket from state_storage.tf
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "clinicflow-state-locks"
    encrypt        = true
  }
}

# ... your existing provider and module blocks remain below ...

provider "aws" {
  region = "us-east-1"
}

# Client 1: Your Pilot MedSpa
module "pilot_medspa" {
  source = "./modules/clinicflow-vault"

  client_name = "AlphaAesthetics"
  environment = "Production"
}