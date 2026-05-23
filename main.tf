# ====================================================================
# 1. TERRAFORM & CLOUD BACKEND CONFIGURATION
# ====================================================================
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "clinicflow-state-vault-541495491866"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
    # use_lockfile = true # Commented out for local binary compatibility
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
} # <--- THIS CLOSING BRACE WAS MISSING OR MISPLACED

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
}

  # Core network variables being passed into the module namespace
  vpc_id             = "vpc-0867358f77f706712"
  db_security_group  = "sg-033cffc58e84d62df" # Extracted from your live AWS data table
  web_security_group = "sg-0c383a377dbbef6fa" # Extracted from your live AWS data table
}