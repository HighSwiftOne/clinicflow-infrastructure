# ====================================================================
# VIRTUAL PRIVATE CLOUD ROOT NETWORK
# ====================================================================
resource "aws_vpc" "clinicflow_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ClinicFlow-Core-VPC"
    Environment = "Production"
  }
}

# ====================================================================
# DEFAULT SECURITY GROUP RECONCILIATION
# ====================================================================
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  tags = {
    Name        = "ClinicFlow-Default-Blackhole"
    Environment = "Production"
  }
}

# ====================================================================
# LAYER 3 VPC FLOW LOG ENGINE
# ====================================================================
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.clinicflow_vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/aws/vpc/clinicflow-core-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.clinicflow_cmk.arn
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "ClinicFlow-VPC-Flow-Log-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "ClinicFlow-VPC-Flow-Log-Policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSVPCFlowLogWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_log_group.arn}:*"
      }
    ]
  })
}

# ====================================================================
# PERIMETER INTERNET ROUTING GATEWAY
# ====================================================================
resource "aws_internet_gateway" "clinicflow_igw" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  tags = {
    Name        = "ClinicFlow-Gateway"
    Environment = "Production"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clinicflow_igw.id
  }

  tags = {
    Name        = "ClinicFlow-Public-RouteTable"
    Environment = "Production"
  }
}

# ====================================================================
# SUB NETWORKING LAYOUTS (PUBLIC TIER TIGHTENED)
# ====================================================================
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  # FIXED: Closes the public deployment trapdoor vulnerability (Resolves CKV_AWS_130)
  map_public_ip_on_launch = false

  tags = { Name = "ClinicFlow-Public-Subnet-A" }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  # FIXED: Closes the public deployment trapdoor vulnerability (Resolves CKV_AWS_130)
  map_public_ip_on_launch = false

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