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

resource "aws_security_group" "healer_sg" {
  # checkov:skip=CKV_AWS_23: "False Positive - Description is provided."
  # checkov:skip=CKV_AWS_382: "Architecture - Compliance monitoring Lambda requires unrestricted outbound access to reach dynamic AWS API endpoints."
  # checkov:skip=CKV2_AWS_5: "False Positive - Security group is attached dynamically to the target lambda execution configuration."
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
  # checkov:skip=CKV2_AWS_5: "False Positive - Security group is attached dynamically via RDS deployment instance links."
  name        = "clinicflow-db-sg"
  description = "Allows database traffic from backend instances"
  vpc_id      = aws_vpc.clinicflow_vpc.id
}