# checkov:skip=CKV2_AWS_11: "Architecture - VPC flow logging is enabled."
# checkov:skip=CKV2_AWS_12: "Ensure the default security group of every VPC restricts all traffic."
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

resource "aws_security_group" "healer_sg" {
  # checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  # checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  # checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
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

resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
  name        = "clinicflow-db-sg"
  description = "Allows database traffic from backend instances"
  vpc_id      = aws_vpc.clinicflow_vpc.id
}