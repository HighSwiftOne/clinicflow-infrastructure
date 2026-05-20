# ====================================================================
# INGRESS LAYER 4 FIREWALL (APPLICATION LOAD BALANCER PERIMETER)
# ====================================================================
resource "aws_security_group" "web_sg" {
  name        = "clinicflow-web-alb-sg"
  description = "Controls encrypted public HTTPS ingress to the Application Load Balancer tier"
  vpc_id      = aws_vpc.clinicflow_vpc.id

  ingress {
    description = "Allow secure encrypted HTTPS traffic from public endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # checkov:skip=CKV_AWS_260: "Architecture - Port 80 is explicitly open to capture and forcefully upgrade traffic to port 443."
    description = "Allow standard HTTP traffic for secure TLS enforcement redirection loops"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Harden Ingress Infiltration - Outbound traffic restricted strictly to internal compute tasks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # FIXED: Restricts network boundary directly to the internal autoscaling firewall group ID wrapper (Resolves CKV_AWS_382)
    security_groups = [aws_security_group.healer_sg.id]
  }

  tags = {
    Name        = "ClinicFlow-ALB-SecurityGroup"
    Environment = "Production"
  }
}