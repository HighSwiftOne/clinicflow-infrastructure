# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. APPLICATION HARDENED LOAD BALANCER TIER (ROOT ELIGIBLE)
import {
  to = module.pilot_medspa.aws_lb.clinicflow_alb
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda"
}

# 2. APPLICATION ROUTING TARGET GROUP (ROOT ELIGIBLE)
import {
  to = module.pilot_medspa.aws_lb_target_group.clinicflow_tg
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:targetgroup/ClinicFlow-TargetGroup/a39fa0a9aae1d6e0"
}

# 3. PRODUCTION DATABASE INSTANCE ADOPTION (ROOT ELIGIBLE)
import {
  to = module.pilot_medspa.aws_db_instance.clinicflow_db
  id = "db-LOMYBPPO7SUDALTOQRCLJQWGTY"
}

# 4. SERVER-SIDE DATABASE RETENTION SUBNET GROUP (ROOT ELIGIBLE)
import {
  to = module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group
  id = "clinicflow-db-subnet-group"
}

# 5. AWS TRANSFER SFTP INSTANCE ENGINE (ROOT ELIGIBLE)
import {
  to = module.pilot_medspa.aws_transfer_server.clinicflow_sftp
  id = "s-1b83a4f0a9d140a4a"
}# Cache Invalidation Override: 2026-05-23
