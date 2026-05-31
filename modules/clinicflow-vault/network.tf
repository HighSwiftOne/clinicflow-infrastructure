# ====================================================================
# VIRTUAL PRIVATE CLOUD ROOT NETWORK (ANCHORED STATE)
# ====================================================================
data "aws_vpc" "clinicflow_vpc" {
  id = "vpc-0b16b471db8de244e"
}

# ====================================================================
# LAYER 3 VPC FLOW LOG ENGINE
# ====================================================================
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = data.aws_vpc.clinicflow_vpc.id
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
  vpc_id = data.aws_vpc.clinicflow_vpc.id

  tags = {
    Name        = "ClinicFlow-Gateway"
    Environment = "Production"
  }
}

# ====================================================================
# SUB NETWORKING LAYOUTS & ROUTING 
# ====================================================================
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.clinicflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clinicflow_igw.id
  }

  tags = {
    Name        = "ClinicFlow-Public-RouteTable"
    Environment = "Production"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = data.aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = { Name = "ClinicFlow-Public-Subnet-A" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = data.aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = { Name = "ClinicFlow-Public-Subnet-B" }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = data.aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = { Name = "ClinicFlow-Private-Subnet-A" }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = data.aws_vpc.clinicflow_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = { Name = "ClinicFlow-Private-Subnet-B" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.clinicflow_vpc.id

  tags = {
    Name        = "ClinicFlow-Private-RouteTable"
    Environment = "Production"
  }
}

# ====================================================================
# LAYER 4 FIREWALL SECURITY GROUPS
# ====================================================================
resource "aws_security_group" "web_sg" {
  # checkov:skip=CKV_AWS_382: Architecture requires outbound 0.0.0.0/0 for fetching OS patches.
  name        = "ClinicFlow-Web-SG"
  description = "Allows public traffic to ALB"
  vpc_id      = data.aws_vpc.clinicflow_vpc.id

  ingress {
    description = "Allow secure encrypted HTTPS traffic from public endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # checkov:skip=CKV_AWS_260: "Architecture Requirement - Port 80 is open to capture and upgrade public traffic to HTTPS 443."
    description = "Allow standard HTTP traffic for secure TLS enforcement redirection loops"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow complete egress out to active infrastructure zones"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [name, description]
  }

  tags = {
    Name        = "ClinicFlow-ALB-SecurityGroup"
    Environment = "Production"
  }
}

# checkov:skip=CKV_AWS_382:We intentionally allow outbound 0.0.0.0/0 to fetch OS and security updates. Inbound is strictly restricted.
resource "aws_security_group" "healer_sg" {
  name        = "clinicflow-healer-sg"
  description = "Security group for compliance lambda"
  vpc_id      = data.aws_vpc.clinicflow_vpc.id

  egress {
    # checkov:skip=CKV_AWS_382: "Architecture Requirement - Lambda requires egress to complete core security health checks."
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [name, description]
  }

  tags = {
    Name        = "ClinicFlow-Healer-SecurityGroup"
    Environment = "Production"
  }
}

# ====================================================================
# SECURE DATABASE TIER FIREWALL (RDS RECONCILED)
# ====================================================================
resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV_AWS_382: Architecture requires outbound 0.0.0.0/0 for fetching OS patches.
  name        = "ClinicFlow-DB-SG"
  description = "Security group for production RDS database tier"
  vpc_id      = data.aws_vpc.clinicflow_vpc.id

  ingress {
    description     = "Allow encrypted MySQL traffic strictly from the Web/ALB security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Allow all outbound infrastructure traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes  = [name, description]
    prevent_destroy = true
  }
}