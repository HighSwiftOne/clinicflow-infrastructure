# ====================================================================
# GLOBAL IDENTITY & ACCESS IMPORTS
# ====================================================================

import {
  to = aws_iam_role.github_actions_role
  id = "ClinicFlow-GitHub-Actions-Role"
}

import {
  to = module.pilot_medspa.aws_iam_instance_profile.image_builder_profile
  id = "clinicflow-image-builder-profile"
}

# ====================================================================
# NETWORK CORE & ROUTING IMPORTS
# ====================================================================

import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0867358f77f706712"
}

import {
  to = module.pilot_medspa.aws_internet_gateway.igw
  id = "igw-0a9d4a31fc71125b2"
}

# Public Subnets Data Planes
import {
  to = module.pilot_medspa.aws_subnet.public_a
  id = "subnet-0708f51dfcf5451a4"
}

import {
  to = module.pilot_medspa.aws_subnet.public_b
  id = "subnet-04b3cf4eb32d72134"
}

# Private Subnets Data Planes
import {
  to = module.pilot_medspa.aws_subnet.private_a
  id = "subnet-0db3afef566f194c7"
}

import {
  to = module.pilot_medspa.aws_subnet.private_b
  id = "subnet-0cb8bf5fc62e841f9"
}

# ====================================================================
# FIREWALL & SECURITY GROUP IMPORTS
# ====================================================================

import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-04cb5fb1be4d8f1d7"
}

import {
  to = module.pilot_medspa.aws_security_group.healer_sg
  id = "sg-0cf9bf77fa8f6e2e5"
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-06cf4bfa8ef8c2f1f"
}

# ====================================================================
# COMPUTE & ROUTING INGRESS IMPORTS
# ====================================================================

import {
  to = module.pilot_medspa.aws_lb_target_group.clinicflow_tg
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:targetgroup/ClinicFlow-TargetGroup/7b86ad491f2e1a3d"
}

# ====================================================================
# PRIOR ESTABLISHED BASELINE STATE STORAGE IMPORTS
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

import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::541495491866:oidc-provider/token.actions.githubusercontent.com"
}

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