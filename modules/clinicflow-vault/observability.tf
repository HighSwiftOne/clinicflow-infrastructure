# ============================================
# VARIABLES (configure in root variables.tf)
# ============================================
variable "alert_email" {
  description = "Email address for security alerts (SNS subscription)"
  type        = string
  sensitive   = false
}

# ====================================================================
# OBSERVABILITY - SNS ALERT MEGAPHONE
# ====================================================================
resource "aws_sns_topic" "security_alerts" {
  name = "clinicflow-security-alerts"
  
  # ELITE GUARDRAIL: KMS Encryption for the SNS Topic (Fixes CKV_AWS_26)
  kms_master_key_id = aws_kms_key.clinicflow_cmk.arn 
}

  # Enable FIFO? No, standard is fine for alerts.
  # Enable delivery status logging? Optional.
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget  = 20
        maxDelayTarget  = 20
        numRetries      = 3
        backoffFunction = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = {
    Name        = "ClinicFlow-Security-Alerts"
    Environment = "Production"
  }
}



# Email subscription (SNS uses email as protocol)
resource "aws_sns_topic_subscription" "security_team_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================
# SNS TOPIC POLICY – Allow EventBridge & CloudWatch
# ============================================
resource "aws_sns_topic_policy" "security_alerts_policy" {
  arn = aws_sns_topic.security_alerts.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]
  }

  statement {
    sid    = "AllowCloudWatchToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]
  }

  # Optional: allow your own account to manage the topic
  statement {
    sid    = "AllowManagement"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions   = ["SNS:*"]
    resources = [aws_sns_topic.security_alerts.arn]
  }
}

# ============================================
# EVENTBRIDGE RULE – Config Non-Compliance
# ============================================
resource "aws_cloudwatch_event_rule" "config_non_compliant" {
  name        = "clinicflow-config-non-compliant"
  description = "Trigger when AWS Config rule evaluation becomes NON_COMPLIANT"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType = ["ComplianceChangeNotification"]
      configRuleName = [{
        prefix = "clinicflow-" # Matches all our Config rules
      }]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_config_violation" {
  rule      = aws_cloudwatch_event_rule.config_non_compliant.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}

# ============================================
# CLOUDWATCH METRIC ALARM – WAF Blocked Requests
# ============================================
# Use the WAF web ACL's metric (adjust dimensions if you have multiple WAFs)
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "clinicflow-waf-blocked-requests-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "WAF blocked more than 100 requests in 5 minutes – possible attack"
  treat_missing_data  = "notBreaching"

  # Dimensions: WebACL and Region (adjust to match your WAF)
  dimensions = {
    WebACL = aws_wafv2_web_acl.clinicflow_waf.name
    Region = data.aws_region.current.name
  }

  alarm_actions = [aws_sns_topic.security_alerts.arn]
}

# Optional: Also alarm on high rate of SQLi or XSS specific rules
# You can add more alarms for specific rule groups if desired.