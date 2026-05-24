# ====================================================================
# CLINICFLOW CORE PRODUCTION STATE RECONCILIATION LAYER
# ====================================================================

# 1. CORE VPC FABRIC GROUNDWORK (The True Anchor)
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
  id = "subnet-0d09d66516dd3f0e2"
}

import {
  to = module.pilot_medspa.aws_subnet.public_b
  id = "subnet-0dbb79900d7a0c3d8"
}

import {
  to = module.pilot_medspa.aws_subnet.private_a
  id = "subnet-00fec48ee266cff16"
}

import {
  to = module.pilot_medspa.aws_subnet.private_b
  id = "subnet-05453892442d2491a"
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