# ====================================================================
# GLOBAL IDENTITY & ACCESS CONTROL IMPORTS
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
# VIRTUAL PRIVATE CLOUD ROOT LINK
# ====================================================================

import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0867358f77f706712"
}

# ====================================================================
# CENTRAL STATE STORAGE BACKEND VAULTS
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