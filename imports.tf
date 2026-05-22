# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. CORE VPC FABRIC GROUNDWORK
import {
  to = module.pilot_medspa.aws_vpc.clinicflow_vpc
  id = "vpc-0867358f77f706712"
}

# 2. PERIMETER NETWORK INTERNET ROUTING GATEWAY (RECONCILED)
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0f388bac1226c68f4" # FIXED: Map to your active physical gateway ID
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
  id = "sg-0cb5078ab8b733e59"
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

# 7. SERVER-SIDE DATABASE RETENTION SUBNET GROUP
import {
  to = module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group
  id = "clinicflow-db-subnet-group"
}

# 8. SECURITY AUTOMATION POLICY PERMISSIONS
import {
  to = module.pilot_medspa.aws_lambda_permission.allow_eventbridge
  id = "ClinicFlow-S3-Healer/AllowExecutionFromEventBridge"
}

# 9. PRODUCTION DATABASE INSTANCE ADOPTION
import {
  to = module.pilot_medspa.aws_db_instance.clinicflow_db
  id = "clinicflow-database-production"
}

# 10. ROUTE TABLE ASSOCIATION ALIGNMENTS (RECONCILED)
import {
  to = module.pilot_medspa.aws_route_table_association.private_a_assoc
  id = "subnet-0965fcc0cbcdd1339/rtb-08adfc8fe51cd0a29" # FIXED: Formatted as SUBNET_ID/ROUTE_TABLE_ID using your live active table
}

import {
  to = module.pilot_medspa.aws_route_table_association.private_b_assoc
  id = "subnet-068d2f33719fb834d/rtb-08adfc8fe51cd0a29" # FIXED: Formatted as SUBNET_ID/ROUTE_TABLE_ID using your live active table
}