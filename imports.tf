# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. CORE VPC FABRIC GROUNDWORK
import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0867358f77f706712"
}

# 2. PERIMETER NETWORK INTERNET ROUTING GATEWAY
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0f388bac1226c68f4"
}

# 3. LAYER 3 SUBNET ROUTING FABRIC MAPPINGS
import {
  to = module.pilot_medspa.aws_subnet.public_a
  id = "subnet-09fa98f477aa6c549"
}

import {
  to = module.pilot_medspa.aws_subnet.public_b
  id = "subnet-0cced3aa961573526"
}

import {
  to = module.pilot_medspa.aws_subnet.private_a
  id = "subnet-0965fcc0cbcdd1339"
}

import {
  to = module.pilot_medspa.aws_subnet.private_b
  id = "subnet-068d2f33719fb834d"
}

# 4. LAYER 4 FIREWALL SECURITY GROUPS
import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-0c383a377dbbef6fa"
}

import {
  to = module.pilot_medspa.aws_security_group.healer_sg
  id = "sg-07da5378daeb9b2db"
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-033cffc58e84d62df"
}

# 5. APPLICATION HARDENED LOAD BALANCER TIER
import {
  to = module.pilot_medspa.aws_lb.clinicflow_alb
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda"
}

# 6. CORE INSTANCE APPLICATION AUTO-SCALING LAUNCH TEMPLATE
import {
  to = module.pilot_medspa.aws_launch_template.clinicflow_lt
  id = "lt-090aefb0ef76eaf63"
}

# 7. PRODUCTION DATABASE INSTANCE ADOPTION
import {
  to = module.pilot_medspa.aws_db_instance.clinicflow_db
  id = "db-LOMYBPPO7SUDALTOQRCLJQWGTY"
}

# 8. SERVER-SIDE DATABASE RETENTION SUBNET GROUP
import {
  to = module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group
  id = "clinicflow-db-subnet-group"
}# Cache Invalidation Pass: 2026-05-23
