# ==============================================================================
# 1. THE LOBBY BOUNCER (WEB TIER SECURITY GROUP)
# ==============================================================================

resource "aws_security_group" "web_sg" {
  name        = "ClinicFlow-Web-SG"
  description = "Allow inbound HTTP/HTTPS traffic from the internet"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  # Inbound HTTP (Port 80)
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS (Port 443)
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound All (Required for servers to fetch software updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-Web-SG"
  }
}

# ==============================================================================
# 2. THE VAULT DOOR (DATABASE TIER SECURITY GROUP)
# ==============================================================================

resource "aws_security_group" "db_sg" {
  name        = "ClinicFlow-DB-SG"
  description = "Strict zero-trust database firewall"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  # Hafner's Rule: Only accept traffic from the Web SG
  ingress {
    description     = "Allow MySQL traffic ONLY from the Web Tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] 
  }

  # Outbound All (Routes through NAT Gateway for zero-trust patching)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClinicFlow-DB-SG"
  }
}
