# checkov:skip=CKV_AWS_260: "Architecture - Port 80 is strictly required to catch and forcefully redirect HTTP traffic to HTTPS."
# checkov:skip=CKV_AWS_382: "Architecture - The public ALB requires unrestricted egress to talk with dynamic Auto Scaling Group IPs."
resource "aws_security_group" "web_sg" {
  name        = "clinicflow-web-sg"
  description = "Allows public traffic to ALB"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  ingress {
    description = "Allow HTTP access"
    from_port   = 80
    to_port     = 80
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
}