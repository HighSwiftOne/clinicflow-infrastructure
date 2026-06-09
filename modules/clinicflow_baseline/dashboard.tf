# ====================================================================
# PHASE 10: EXECUTIVE SECURITY DASHBOARD
# ====================================================================
resource "aws_cloudwatch_dashboard" "executive_security" {
  dashboard_name = "ClinicFlow-Executive-Security-Report"

  dashboard_body = jsonencode({
    widgets = [
      # === TEXT WIDGET: Title & Executive Summary ===
      {
        type = "text"
        properties = {
          markdown = <<-EOT
            # ClinicFlow Executive Security Dashboard
            **Environment:** Production  
            **Region:** ${data.aws_region.current.name}  
            **Account:** ${data.aws_caller_identity.current.account_id}  
            
            ## Security Posture Summary
            - **WAF**: Blocked malicious requests (Log4j, SQLi, XSS)
            - **ALB**: Total API traffic volume
            - **GuardDuty**: Active threat findings
            
            _Last updated: real-time_
          EOT
        }
        height = 3
        width  = 24
        x      = 0
        y      = 0
      },

      # === WAF PERIMETER WIDGET (Blocked Requests) ===
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.clinicflow_waf.name, "Region", data.aws_region.current.name]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "WAF - Blocked Requests (last 24h)"
          yAxis = {
            left = {
              label     = "Count"
              showUnits = false
            }
          }
          view    = "timeSeries"
          stacked = false
        }
        height = 8
        width  = 12
        x      = 0
        y      = 3
      },

      # === ALB TRAFFIC WIDGET (Request Count) ===
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.clinicflow_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "ALB - Total Requests (last 24h)"
          yAxis = {
            left = {
              label     = "Requests"
              showUnits = false
            }
          }
          view    = "timeSeries"
          stacked = false
        }
        height = 8
        width  = 12
        x      = 12
        y      = 3
      },

      # === GUARDDUTY FINDINGS WIDGET (Severity Count) ===
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/GuardDuty", "FindingCount", "DetectorId", aws_guardduty_detector.clinicflow.id, "Severity", "MEDIUM"],
            [".", "FindingCount", ".", ".", "Severity", "HIGH"],
            [".", "FindingCount", ".", ".", "Severity", "CRITICAL"]
          ]
          period = 3600
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "GuardDuty Findings (Hourly – Medium, High, Critical)"
          yAxis = {
            left = {
              label     = "Findings"
              showUnits = false
            }
          }
          view    = "timeSeries"
          stacked = false
        }
        height = 8
        width  = 24
        x      = 0
        y      = 11
      },

      # === TEXT WIDGET: Compliance Status ===
      {
        type = "text"
        properties = {
          markdown = <<-EOT
            ## HIPAA Compliance Indicators
            - **AWS Config** – Continuous rule evaluation (S3 encryption, RDS encryption)
            - **GuardDuty** – Active hypervisor threat detection
            - **WAF** – Perimeter defense against OWASP Top 10
            - **Backup** – Immutable WORM vault (7-year retention)
            
            *For detailed granular compliance reports, see the AWS Config console.*
          EOT
        }
        height = 4
        width  = 24
        x      = 0
        y      = 19
      }
    ]
  })
}