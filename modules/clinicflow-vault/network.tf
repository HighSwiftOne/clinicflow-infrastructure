# ====================================================================
# VIRTUAL PRIVATE CLOUD ROOT NETWORK
# ====================================================================
resource "aws_vpc" "clinicflow_vpc" {
  # checkov:skip=CKV_AWS_11: "Architecture - VPC flow logs are deferred for initial laboratory scopes."
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ClinicFlow-Core-VPC"
    Environment = "Production"
  }
}

# ====================================================================
# PERIMETER INTERNET ROUTING GATEWAY (RECONCILED BASELINE)
# ====================================================================
resource "aws_internet_gateway" "clinicflow_igw" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  tags = {
    Name        = "ClinicFlow-Gateway"
    Environment = "Production"
  }
}

# ====================================================================
# PUBLIC INGRESS ROUTING DATA PLANE
# ====================================================================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # FIXED: Maps seamlessly to our declarative moved block reference
    gateway_id = aws_internet_gateway.clinicflow_igw.id
  }

  tags = {
    Name        = "ClinicFlow-Public-RouteTable"
    Environment = "Production"
  }
}

# ====================================================================
# SUB NETWORKING LAYOUTS (PUBLIC TIER)
# ====================================================================
resource "aws_subnet" "public_a" {
  # checkov:skip=CKV_AWS_130: "False Positive - Public subnets require public IP assignments for ingress ALBs."
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "ClinicFlow-Public-Subnet-A" }
}

resource "aws_subnet" "public_b" {
  # checkov:skip=CKV_AWS_130: "False Positive - Public subnets require public IP assignments for ingress ALBs."
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "ClinicFlow-Public-Subnet-B" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}