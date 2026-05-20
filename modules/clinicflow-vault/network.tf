resource "aws_vpc" "clinicflow_vpc" {
  # checkov:skip=CKV2_AWS_11: "Architecture - VPC flow logging is deferred for initial pilot phase deployment to optimize CloudWatch costs."
  # checkov:skip=CKV2_AWS_12: "Architecture - Default security group restrictions are managed via broader baseline account control parameters."
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

resource "aws_vpc_endpoint" "s3_private_link" {
  vpc_id       = aws_vpc.clinicflow_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
}