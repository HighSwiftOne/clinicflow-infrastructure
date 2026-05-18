variable "client_name" {
  description = "The name of the MedSpa client"
  type        = string
  default     = "ClinicFlow-Core"
}

variable "environment" {
  description = "Dev, Staging, or Production"
  type        = string
  default     = "Production"
}

variable "aws_region" {
  default = "us-east-1"
}