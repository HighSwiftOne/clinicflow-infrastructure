# ====================================================================
# 1. TERRAFORM & CLOUD BACKEND CONFIGURATION
# ====================================================================
terraform {
  required_version = ">= 1.5.0"

  # ⚠️ TEMPORARY RETREAT: Commented out to fix the missing S3 bucket
  # backend "s3" {
  #   bucket         = "clinicflow-state-vault-541495491866"
  #   key            = "production/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "clinicflow-state-lock"
  #   encrypt        = true
  # }

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

  # Explicit parameter injection
  vpc_id = var.target_vpc_id
}