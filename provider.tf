terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

  # DevSecOps Tie-in: Default Tags
  # Every single resource created will automatically get these tags for auditing.
  default_tags {
    tags = {
      Project     = "ClinicFlow"
      Environment = "Production"
      ManagedBy   = "Terraform"
      HIPAA_Tier  = "High_Security"
    }
  }
}
