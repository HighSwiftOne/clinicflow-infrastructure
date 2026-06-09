# ====================================================================
# PHASE 9: AI-DRIVEN THREAT DETECTION (GUARDDUTY)
# ====================================================================
resource "aws_guardduty_detector" "clinicflow" {
  # checkov:skip=CKV2_AWS_3: ClinicFlow uses a per-tenant, single-account architecture for HIPAA isolation. Org-wide GuardDuty is not applicable.
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Name        = "ClinicFlow-GuardDuty"
    Environment = "Production"
    HIPAA       = "MalwareProtection"
  }
}

# ====================================================================
# EVENTBRIDGE TRIPWIRE FOR INTRUSION ATTEMPTS
# ====================================================================
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "clinicflow-guardduty-findings"
  description = "Capture Medium/High GuardDuty findings for immediate security alerting"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 4.0] }]
    }
  })
}

# ====================================================================
# ALERT ROUTING (WIRED TO EXISTING SNS MEGAPHONE)
# ====================================================================
resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindingsToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}