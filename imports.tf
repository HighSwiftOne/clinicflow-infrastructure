# ====================================================================
# NETWORK PARALLEL INTEGRATION ROOT LINK (VERIFIED ACTIVE)
# ====================================================================

import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0867358f77f706712"
}

# ====================================================================
# GLOBAL IDENTITY & ACCESS CONTROL IMPORTS (VERIFIED ACTIVE)
# ====================================================================

import {
  to = aws_iam_role.github_actions_role
  id = "ClinicFlow-GitHub-Actions-Role"
}

import {
  to = module.pilot_medspa.aws_iam_instance_profile.image_builder_profile
  id = "clinicflow-image-builder-profile"
}

import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::541495491866:oidc-provider/token.actions.githubusercontent.com"
}

# ====================================================================
# MASTER COMPLIANCE VAULT & AUDIT TRAIL IMPORTS (VERIFIED ACTIVE)
# ====================================================================

import {
  to = module.pilot_medspa.aws_s3_bucket.clinicflow_logs
  id = "clinicflow-logs-clinicflow-core-541495491866"
}

import {
  to = module.pilot_medspa.aws_iam_policy.image_builder_boundary
  id = "arn:aws:iam::541495491866:policy/ClinicFlow-ImageBuilder-Boundary"
}

import {
  to = module.pilot_medspa.aws_iam_role.image_builder_role
  id = "clinicflow-image-builder-role"
}

import {
  to = module.pilot_medspa.aws_iam_role.lambda_healer_role
  id = "ClinicFlow-S3-Healer-Role"
}

import {
  to = module.pilot_medspa.aws_iam_role.sftp_logging_role
  id = "ClinicFlow-SFTP-Logging-Role"
}

import {
  to = module.pilot_medspa.aws_iam_role.receptionist_sftp_role
  id = "ClinicFlow-Receptionist-SFTP"
}

import {
  to = module.pilot_medspa.aws_cloudtrail.audit_trail
  id = "clinicflow-audit-trail"
}

import {
  to = module.pilot_medspa.aws_imagebuilder_component.clinicflow_hardening
  id = "arn:aws:imagebuilder:us-east-1:541495491866:component/clinicflow-web-hardening/1.0.0/1"
}

# ====================================================================
# CENTRAL STATE STORAGE BACKEND VAULTS (VERIFIED ACTIVE)
# ====================================================================

import {
  to = aws_s3_bucket.terraform_state
  id = "clinicflow-state-vault-541495491866"
}

import {
  to = aws_s3_bucket.old_state_storage
  id = "clinicflow-state-storage-541495491866"
}

import {
  to = aws_dynamodb_table.terraform_locks
  id = "clinicflow-tflocks"
}

import {
  to = aws_dynamodb_table.old_terraform_locks
  id = "clinicflow-state-locks"
}