# ====================================================================
# 1. TERRAFORM & CLOUD BACKEND CONFIGURATION
# ====================================================================
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "clinicflow-state-vault-541495491866"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ====================================================================
# 2. PROVIDER SPECIFICATION
# ====================================================================
provider "aws" {
  region = "us-east-1"
}

# ====================================================================
# 3. ROOT MODULE DEPLOYMENT CALLER
# ====================================================================
module "pilot_medspa" {
  source = "./modules/clinicflow-vault"

  # EXPLICIT PARAMETER INJECTION
  vpc_id              = "vpc-0b16b471db8de244e"
  acm_certificate_arn = "arn:aws:acm:us-east-1:541495491866:certificate/0f7881ea-dadb-4d5d-b4ba-ab04c866efd9"
}