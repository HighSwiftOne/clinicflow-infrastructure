# ============================================
# IAM ROLE FOR AWS BACKUP
# ============================================
resource "aws_iam_role" "backup_role" {
  name = "ClinicFlow-Backup-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ============================================
# IMMUTABLE BACKUP VAULT (WORM Lock)
# ============================================
resource "aws_backup_vault" "compliance_vault" {
  name = "clinicflow-compliance-vault-v2"
  # Target the CMK directly, no module prefix needed
  kms_key_arn = aws_kms_key.clinicflow_cmk.arn

  tags = {
    Environment = "Production"
    Service     = "Backup"
    HIPAA       = "ePHI"
  }
}

resource "aws_backup_vault_lock_configuration" "compliance_lock" {
  backup_vault_name   = aws_backup_vault.compliance_vault.name
  min_retention_days  = 30
  max_retention_days  = 2555
  changeable_for_days = 3
}

# ============================================
# BACKUP PLAN
# ============================================
resource "aws_backup_plan" "daily_plan" {
  name = "clinicflow-daily-backup"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = aws_backup_vault.compliance_vault.name
    schedule          = "cron(0 5 * * ? *)" # 5:00 AM UTC daily
    start_window      = 60
    completion_window = 120

    lifecycle {
      cold_storage_after = 30
      delete_after       = 2555 # 7 Years (HIPAA minimum)
    }
  }

  tags = {
    Environment = "Production"
  }
}

# ============================================
# TAG-BASED RESOURCE SELECTION
# ============================================
resource "aws_backup_selection" "production_resources" {
  name         = "clinicflow-backup-selection"
  plan_id      = aws_backup_plan.daily_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment" # <--- AWS requires this exact prefix
      value = "Production"
    }
  }

  resources = [
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
    "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:*",
    "arn:aws:s3:::clinicflow-*",
  ]
}