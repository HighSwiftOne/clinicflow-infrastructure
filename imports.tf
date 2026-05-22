# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. PERIMETER NETWORK INTERNET ROUTING GATEWAY
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0ab1b8086481499dc" # Connected cleanly via live network paths [cite: 10, 45, 126]
}

# 2. APPLICATION HARDENED LOAD BALANCER COMPUTE TIER
import {
  to = module.pilot_medspa.aws_lb.clinicflow_alb
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda" # Fully matched in log [cite: 10, 48, 52, 56, 138, 146]
}

# 3. CORE INSTANCE APPLICATION AUTO-SCALING LAUNCH TEMPLATE
import {
  to = module.pilot_medspa.aws_launch_template.clinicflow_lt
  id = "lt-090aefb0ef76eaf63" # Fully matched in log [cite: 10, 19, 47, 48, 100, 129, 131]
}

# 4. SERVER-SIDE DATABASE RETENTION SUBNET GROUP
import {
  to = module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group
  id = "clinicflow-db-subnet-group" # Successfully resolved across clusters [cite: 10, 25, 43, 106, 124]
}

# 5. SECURITY AUTOMATION POLICY PERMISSIONS
import {
  to = module.pilot_medspa.aws_lambda_permission.allow_eventbridge
  id = "ClinicFlow-S3-Healer/AllowExecutionFromEventBridge" # Fully matched in log [cite: 10, 46, 128]
}

# 6. PRODUCTION DATABASE INSTANCE ADOPTION
import {
  to = module.pilot_medspa.aws_db_instance.clinicflow_db
  id = "clinicflow-database-production" # Maps active production database asset to stop collisions
}