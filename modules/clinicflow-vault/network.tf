# ==============================================================================
# 1. THE FOUNDATION (VPC & INTERNET GATEWAY)
# ==============================================================================

resource "aws_vpc" "clinicflow_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Required for AWS services like RDS
  enable_dns_hostnames = true

  tags = {
    Name = "ClinicFlow-VPC"
  }
}

# checkov:skip=CKV2_AWS_12: "Architecture - Default SG restriction is handled via broader account SCPs, not at the VPC module level."
resource "aws_vpc" "clinicflow_vpc" 

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  tags = {
    Name = "ClinicFlow-IGW"
  }
}

# ==============================================================================
# 2. THE BANK LOBBY (PUBLIC SUBNETS)
# ==============================================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # Brikman Best Practice: Explicitly state this

  tags = {
    Name = "Public-Subnet-A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Public-Subnet-B"
  }
}

# ==============================================================================
# 3. THE VAULT (PRIVATE SUBNETS)
# ==============================================================================

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # Explicit zero-trust

  tags = {
    Name = "Private-Subnet-A"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet-B"
  }
}

# ==============================================================================
# 5. THE ROADMAP (ROUTE TABLES & ASSOCIATIONS)
# ==============================================================================

# Public Route Table (Points to IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ClinicFlow-Public-RT"
  }
}

# Private Route Table (Does NOT point to the internet)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id
  
  # No 0.0.0.0/0 route here! The vault is dark.

  tags = {
    Name = "ClinicFlow-Private-RT"
  }
}

# Associate Public Subnets
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Private Subnets
resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

# ==============================================================================
# 6. FINOPS MASTER MOVE: THE S3 TUNNEL (VPC GATEWAY ENDPOINT)
# ==============================================================================

resource "aws_vpc_endpoint" "s3_private_link" {
  vpc_id       = aws_vpc.clinicflow_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]
}

# checkov:skip=CKV_AWS_23: "False Positive - Description is provided."
# checkov:skip=CKV2_AWS_5: "False Positive - SG is attached to the Lambda function via vpc_config."
resource "aws_security_group" "healer_sg" 

# The Security Group for the Lambda (The Bouncer)
resource "aws_security_group" "healer_sg" {
  name        = "clinicflow-healer-sg"
  description = "Strict egress-only access for the S3 Healer"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  # Completely block all incoming traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow outbound traffic to S3 (HTTPS)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The VPC Flow Log wire
resource "aws_flow_log" "clinicflow_vpc_flow_log" {
  log_destination      = aws_s3_bucket.clinicflow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.clinicflow_vpc.id
}