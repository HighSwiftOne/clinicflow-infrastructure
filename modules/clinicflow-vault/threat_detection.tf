# ====================================================================
# PHASE 9: AI-DRIVEN THREAT DETECTION (GUARDDUTY)
# ====================================================================

resource "aws_guardduty_detector" "clinicflow" {
  # checkov:skip=CKV2_AWS_3: ClinicFlow uses a per-tenant, single-account architecture for HIPAA isolation. Org-wide GuardDuty is not applicable.
  enable = true
  
  # ... (keep your existing configurations below this)
}

  # HIPAA requires continuous monitoring; 15 minutes is the AWS minimum threshold
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

  # ELITE GUARDRAIL: Only trigger on Severity 4.0 (Medium) or higher to prevent alert fatigue
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

  # Hooks seamlessly into the SNS topic we built in observability.tf
  arn = aws_sns_topic.security_alerts.arn
}