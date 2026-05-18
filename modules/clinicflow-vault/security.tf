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

  egress {
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

# checkov:skip=CKV_AWS_260: "Architecture - Port 80 is strictly required to forcefully redirect HTTP to HTTPS."
# checkov:skip=CKV_AWS_382: "Architecture - The ALB requires unrestricted egress to reach the dynamic IPs of the Auto Scaling Group."
resource "aws_security_group" "web_sg" {

  ingress {
    description     = "Allow MySQL from Web SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # IN aws_security_group.db_sg
  egress {
    description = "Allow database to communicate ONLY within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Replaces 0.0.0.0/0 with internal VPC routing only
    cidr_blocks = [aws_vpc.clinicflow_vpc.cidr_block] 
  }

  tags = {
    Name = "ClinicFlow-DB-SG"
  }
}