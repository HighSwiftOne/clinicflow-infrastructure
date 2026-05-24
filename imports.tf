# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. CORE VPC FABRIC GROUNDWORK
import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0b16b471db8de244e"
}

# 2. PERIMETER NETWORK INTERNET ROUTING GATEWAY
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-027aca49c9daf7422"
}

# 3. LAYER 3 SUBNET ROUTING FABRIC MAPPINGS
import {
  to = module.pilot_medspa.aws_subnet.public_a
  id = "subnet-0d09d66516dd3f0e2" # 10.0.1.0/24
}

import {
  to = module.pilot_medspa.aws_subnet.public_b
  id = "subnet-0dbb79900d7a0c3d8" # 10.0.2.0/24
}

import {
  to = module.pilot_medspa.aws_subnet.private_a
  id = "subnet-00fec48ee266cff16" # 10.0.3.0/24
}

import {
  to = module.pilot_medspa.aws_subnet.private_b
  id = "subnet-05453892442d2491a" # 10.0.4.0/24
}

# 4. LAYER 4 FIREWALL SECURITY GROUPS
import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-050e40bfd8610eb8e"
}

import {
  to = module.pilot_medspa.aws_security_group.healer_sg
  id = "sg-007bf3993add53c83"
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

# 6. APPLICATION ROUTING TARGET GROUP
import {
  to = module.pilot_medspa.aws_lb_target_group.clinicflow_tg
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:targetgroup/ClinicFlow-TargetGroup/a39fa0a9aae1d6e0"
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
}

# 9. AWS TRANSFER SFTP INSTANCE ENGINE
import {
  to = module.pilot_medspa.aws_transfer_server.clinicflow_sftp
  id = "s-1b83a4f0a9d140a4a"
}