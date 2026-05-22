# ====================================================================
# CLINICFLOW PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. THE RECONCILED INTERNET GATEWAY
import {
  to = module.pilot_medspa.aws_internet_gateway.clinicflow_igw
  id = "igw-0f388bac1226c68f4"
}

# 2. THE APPLICATION REALITY TARGET GROUP
import {
  to = module.pilot_medspa.aws_lb_target_group.clinicflow_tg
  id = "arn:aws:elasticloadbalancing:us-east-1:541495491866:targetgroup/ClinicFlow-TargetGroup/a39fa0a9aae1d6e0"
}

# 3. THE LAYER 3 SUBNET FABRIC MAPPINGS
import {
  to = module.pilot_medspa.aws_subnet.public_a
  id = "subnet-09fa98f477aa6c549" # Aligned with 10.0.1.0/24 [cite: 3, 125]
}

import {
  to = module.pilot_medspa.aws_subnet.public_b
  id = "subnet-0cced3aa961573526" # Aligned with 10.0.2.0/24 [cite: 3, 134]
}

import {
  to = module.pilot_medspa.aws_subnet.private_a
  id = "subnet-0965fcc0cbcdd1339" # Aligned with 10.0.3.0/24 [cite: 3, 108]
}

import {
  to = module.pilot_medspa.aws_subnet.private_b
  id = "subnet-068d2f33719fb834d" # Aligned with 10.0.4.0/24 [cite: 3, 117]
}

# 4. THE LAYER 4 FIREWALL WRAPPERS
import {
  to = module.pilot_medspa.aws_security_group.healer_sg
  id = "sg-07da5378daeb9b2db" # Aligned with clinicflow-healer-sg [cite: 3, 88]
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-033cffc58e84d62df" # Aligned with clinicflow-db-sg [cite: 3, 83]
}

import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-021ebf61df1a432c6" # Aligned with clinicflow-web-sg [cite: 3, 89]
}