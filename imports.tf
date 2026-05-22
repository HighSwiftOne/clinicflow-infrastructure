# ====================================================================
# CLINICFLOW PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. THE PERIMETER INTERNET ROUTING GATEWAY (RECONCILED)
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0f388bac1226c68f4"
}

# 2. THE APPLICATION REALITY TARGET GROUP
import {
  to = module.pilot_medspa.aws_lb_target_group.clinicflow_tg
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:targetgroup/ClinicFlow-TargetGroup/a2a47328fd71adf2"
}

# 3. THE LAYER 3 SUBNET FABRIC MAPPINGS
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

# 4. THE LAYER 4 FIREWALL WRAPPERS
import {
  to = module.pilot_medspa.aws_security_group.healer_sg
  id = "sg-07da5378daeb9b2db"
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-033cffc58e84d62df"
}

import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-0cb5078ab8b733e59"
}