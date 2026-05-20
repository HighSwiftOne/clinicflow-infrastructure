# ==========================================
# 1. TERRAFORM INITIALIZATION CONFIGURATION
# ==========================================
terraform {
  required_version = ">= 1.5.0"

  # TEMPORARY BOOTSTRAP OVERRIDE: 
  # We use local execution tracking to build the bucket first, breaking the 404 loop.
  # backend "s3" {
  #   bucket       = "clinicflow-state-vault-541495491866"
  #   key          = "production/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true 
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==========================================
# 2. PROVIDER SPECIFICATION
# ==========================================
provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 3. ROOT MODULE DEPLOYMENT CALLER
# ==========================================
module "pilot_medspa" {
  source = "./modules/clinicflow-vault"
}