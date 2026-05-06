resource "aws_security_group" "web_sg" {
  name        = "ClinicFlow-Web-SG"
  description = "Allow inbound HTTP/HTTPS traffic from the internet"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  # checkov:skip=CKV_AWS_260:Architecture - Port 80 must be open to perform the HTTP to HTTPS 301 redirect.

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS ONLY for secure software patching"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-Web-SG"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "ClinicFlow-DB-SG"
  description = "Strict zero-trust database firewall"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  ingress {
    description     = "Allow MySQL traffic ONLY from the Web Tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] 
  }

  egress {
    description = "Allow outbound HTTPS ONLY for secure software patching"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-DB-SG"
  }
}