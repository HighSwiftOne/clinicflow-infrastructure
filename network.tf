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
# 4. THE MIDDLEMAN (NAT GATEWAY & ELASTIC IP)
# ==============================================================================

# The NAT Gateway needs a permanent, static Public IP to work
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id # Placed in the Lobby

  # Brikman's Rule: Explicit dependency. Don't build NAT until IGW exists.
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "ClinicFlow-NAT"
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

# Private Route Table (Points to NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

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
# The VPC Flow Log wire
resource "aws_flow_log" "clinicflow_vpc_flow_log" {
  log_destination      = aws_s3_bucket.clinicflow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.clinicflow_vpc.id
}