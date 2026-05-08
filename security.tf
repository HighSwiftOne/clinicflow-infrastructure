# --- Web Tier Security Group (The Front Door) ---
resource "aws_security_group" "web_sg" {
  name        = "ClinicFlow-Web-SG"
  description = "Allow inbound HTTP/HTTPS traffic from the internet" # <-- Change this line back!
  vpc_id      = aws_vpc.clinicflow_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ss {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-Web-SG"
  }
}

# --- Database Security Group (The Vault) ---
resource "aws_security_group" "db_sg" {
  name        = "ClinicFlow-DB-SG"
  description = "Allow traffic only from Web Tier"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  ingress {
    description     = "MySQL from Web SG"
    egrefrom_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Allow all outbound traffic to the internet" # <-- Add this line!
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-DB-SG"
  }
}