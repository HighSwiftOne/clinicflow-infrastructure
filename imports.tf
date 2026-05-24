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
  id = "igw-027aca49c9daf7422" # <--- The True Gateway
}

# 3. LAYER 4 FIREWALL SECURITY GROUPS
import {
  to = module.pilot_medspa.aws_security_group.web_sg
  id = "sg-050e40bfd8610eb8e" # <--- The True Web SG
}

import {
  to = module.pilot_medspa.aws_security_group.db_sg
  id = "sg-03c3efc43abe87cd0" # <--- The True DB SG
}