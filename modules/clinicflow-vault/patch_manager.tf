# ====================================================================
# PHASE 18: AUTONOMOUS FLEET PATCHING (SSM PATCH MANAGER)
# ====================================================================

# ============================================
# PATCH BASELINE (Amazon Linux 2023)
# ============================================
resource "aws_ssm_patch_baseline" "amazon_linux_2023" {
  name             = "clinicflow-al2023-patch-baseline"
  description      = "Patch baseline for Amazon Linux 2023 - auto-approve Critical/Important security patches after 2 days"
  operating_system = "AMAZON_LINUX_2023"

  approval_rule {
    approve_after_days = 2
    compliance_level   = "CRITICAL"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  approval_rule {
    approve_after_days = 14
    compliance_level   = "HIGH"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix", "Enhancement"]
    }
  }

  tags = {
    Environment = "Production"
    Service     = "PatchManager"
    HIPAA       = "RiskManagement"
  }
}

# ============================================
# MAINTENANCE WINDOW (Weekly Sunday at 08:00 UTC)
# ============================================
resource "aws_ssm_maintenance_window" "weekly_patch" {
  name     = "clinicflow-weekly-patch-window"
  schedule = "cron(0 8 ? * SUN *)"
  duration = 3
  cutoff   = 1

  tags = {
    Environment = "Production"
  }
}

# ============================================
# MAINTENANCE WINDOW TARGET
# ============================================
resource "aws_ssm_maintenance_window_target" "production_instances" {
  window_id     = aws_ssm_maintenance_window.weekly_patch.id
  name          = "clinicflow-prod-instances"
  description   = "Target all EC2 instances with tag Environment=Production"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Environment"
    values = ["Production"]
  }
}

# ============================================
# IAM ROLE FOR SSM PATCH TASK
# ============================================
resource "aws_iam_role" "ssm_patch_role" {
  name = "ClinicFlow-SSM-Patch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ssm.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_patch_managed" {
  role       = aws_iam_role.ssm_patch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# ============================================
# MAINTENANCE WINDOW TASK (Install Patches)
# ============================================
resource "aws_ssm_maintenance_window_task" "install_patches" {
  window_id        = aws_ssm_maintenance_window.weekly_patch.id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  service_role_arn = aws_iam_role.ssm_patch_role.arn
  priority         = 1
  max_concurrency  = "2"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.production_instances.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment          = "Install critical security patches on production fleet"
      document_version = "$DEFAULT"
      timeout_seconds  = 3600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}