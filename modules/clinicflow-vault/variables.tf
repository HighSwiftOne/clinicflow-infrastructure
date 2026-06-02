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

variable "alert_email" {
  description = "Email address for receiving SNS security alerts"
  type        = string
  default     = "conallkeenan@gmail.com"
}

variable "vpc_id" {
  description = "The explicit ID of the target VPC for this specific deployment"
  type        = string
}
