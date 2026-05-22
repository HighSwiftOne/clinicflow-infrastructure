# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. PERIMETER NETWORK INTERNET ROUTING GATEWAY
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0ab1b8086481499dc"
}

# 2. APPLICATION HARDENED LOAD BALANCER COMPUTE TIER
import {
  to = module.pilot_medspa.aws_lb.clinicflow_alb
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda" # FIXED: Linked to your verified active ALB handle
}

# 3. CORE INSTANCE APPLICATION AUTO-SCALING LAUNCH TEMPLATE
import {
  to = module.pilot_medspa.aws_launch_template.clinicflow_lt
  id = "lt-083ea4f2e968f4d2a"
}

# 4. COMPLIANT AUDIT IMAGE BUILDER FACTORY CONFIGURATION
import {
  to = module.pilot_medspa.aws_imagebuilder_infrastructure_configuration.clinicflow_infra
  id = "arn:aws:imagebuilder:us-east-1:541495491866:infrastructureconfiguration/clinicflow_infra"
}

# 5. SERVER-SIDE DATABASE RETENTION SUBNET GROUP
import {
  to = module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group
  id = "clinicflow-db-subnet-group"
}

# 6. SECURITY AUTOMATION POLICY PERMISSIONS
import {
  to = module.pilot_medspa.aws_lambda_permission.allow_eventbridge
  id = "ClinicFlow-S3-Healer/AllowExecutionFromEventBridge"
}