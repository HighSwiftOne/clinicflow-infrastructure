# ====================================================================
# PERIMETER THREAT PROTECTION (WAFv2)
# ====================================================================
resource "aws_wafv2_web_acl" "clinicflow_waf" {
  name        = "clinicflow-production-waf"
  description = "HIPAA-compliant WAF blocking SQLi, XSS, and known bad inputs"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # 1. Core Threat Protection (OWASP Top 10)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  # 2. Known Bad Inputs (Log4Shell Protection)
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ClinicFlowWAFMainMetric"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  # MUST start with aws-waf-logs- to be accepted by AWS WAFv2
  name              = "aws-waf-logs-clinicflow"
  retention_in_days = 365
}

resource "aws_wafv2_web_acl_logging_configuration" "clinicflow_waf_logs" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.clinicflow_waf.arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# ====================================================================
# WAF to ALB ATTACHMENT
# ====================================================================
resource "aws_wafv2_web_acl_association" "clinicflow_waf_assoc" {
  resource_arn = aws_lb.clinicflow_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.clinicflow_waf.arn
}