# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. CORE VPC FABRIC GROUNDWORK (ANCHORED TO LIVE DB/ALB)
import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0b16b471db8de244e"
}

# 4. LAYER 4 FIREWALL SECURITY GROUPS (SYNCHRONIZED TO CLI TELEMETRY)
import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-050e40bfd8610eb8e"
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-03c3efc43abe87cd0"
}

# 5. APPLICATION HARDENED LOAD BALANCER TIER
import {
  to = module.pilot_medspa.aws_lb.clinicflow_alb
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda"
}

# 7. PRODUCTION DATABASE INSTANCE ADOPTION
import {
  to = module.pilot_medspa.aws_db_instance.clinicflow_db
  id = "db-LOMYBPPO7SUDALTOQRCLJQWGTY"
}