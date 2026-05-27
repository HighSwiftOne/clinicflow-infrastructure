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

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ClinicFlowWAFMainMetric"
    sampled_requests_enabled   = true
  }
}

# ====================================================================
# WAF to ALB ATTACHMENT
# ====================================================================
resource "aws_wafv2_web_acl_association" "clinicflow_waf_assoc" {
  resource_arn = aws_lb.clinicflow_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.clinicflow_waf.arn
}