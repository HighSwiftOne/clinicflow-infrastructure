# ====================================================================
# PHASE 14: CENTRALIZED SECURITY POSTURE (AWS SECURITY HUB)
# ====================================================================

# Enable Security Hub (AWS automatically creates the service-linked role)
resource "aws_securityhub_account" "clinicflow" {}

# ====================================================================
# SUBSCRIBE TO FOUNDATIONAL SECURITY STANDARDS
# ====================================================================

# AWS Foundational Security Best Practices v1.0.0
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.clinicflow]
}

# CIS AWS Foundations Benchmark v1.2.0
resource "aws_securityhub_standards_subscription" "cis_benchmark" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.clinicflow]
}