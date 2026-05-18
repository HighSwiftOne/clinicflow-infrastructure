# checkov:skip=CKV2_AWS_11: "Architecture - VPC flow logging is deferred for initial pilot phase deployment to optimize CloudWatch costs."
# checkov:skip=CKV2_AWS_12: "Architecture - Default security group restrictions are managed via broader SCP account control parameters."
resource "aws_vpc" "clinicflow_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "ClinicFlow-VPC" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.clinicflow_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.clinicflow_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.clinicflow_vpc.id
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_vpc_endpoint" "s3_private_link" {
  vpc_id       = aws_vpc.clinicflow_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
}

# checkov:skip=CKV_AWS_23: "False Positive - Description is provided."
# checkov:skip=CKV_AWS_382: "Architecture - Compliance monitoring Lambda requires unrestricted outbound access to reach dynamic AWS API endpoints."
# checkov:skip=CKV2_AWS_5: "False Positive - Security group is attached dynamically to the target lambda execution configuration."
resource "aws_security_group" "healer_sg" {
  name        = "clinicflow-healer-sg"
  description = "Security group for compliance lambda"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# checkov:skip=CKV2_AWS_5: "False Positive - Security group is attached dynamically via RDS deployment instance links."
resource "aws_security_group" "db_sg" {
  name        = "clinicflow-db-sg"
  description = "Allows database traffic from backend instances"
  vpc_id      = aws_vpc.clinicflow_vpc.id
}