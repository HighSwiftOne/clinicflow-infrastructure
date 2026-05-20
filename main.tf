# ==========================================
# 1. TERRAFORM & CLOUD BACKEND CONFIGURATION
# ==========================================
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "clinicflow-state-vault-541495491866"
    key          = "production/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

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
# 3. THE RECONCILIATION BYPASS (Resolves Tainted IGW Loop)
# ==========================================
# This statement forces the compiler to automatically untaint and adopt the active internet gateway
moved {
  from = module.pilot_medspa.aws_internet_gateway.igw
  to   = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
}

# ==========================================
# 4. ROOT MODULE DEPLOYMENT CALLER
# ==========================================
module "pilot_medspa" {
  source = "./modules/clinicflow-vault"
}