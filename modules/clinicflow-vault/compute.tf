# ====================================================================
# APPLICATION HARDENED LOAD BALANCER
# ====================================================================

# checkov:skip=CKV2_AWS_76: WAF is attached to ALB via aws_wafv2_web_acl_association in security.tf
resource "aws_lb" "clinicflow_alb" {
  name               = "ClinicFlow-ALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.web_sg.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  # ELITE GUARDRAILS (Checkov Remediation)
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.clinicflow_logs.id
    prefix  = "alb-logs"
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# --- Target Group ---
resource "aws_lb_target_group" "clinicflow_tg" {
  # checkov:skip=CKV_AWS_378:Architecture - Target group is internal. ALB terminates TLS at the edge.
  name     = "ClinicFlow-TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.clinicflow_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

# --- Listeners (Checkov HTTPS Enforcement) ---
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.clinicflow_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_forward" {
  load_balancer_arn = aws_lb.clinicflow_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  # TLS 1.2 Enforcement
  ssl_policy = "ELBSecurityPolicy-TLS12-1-2-2021-06"

  # REPLACE THIS with your actual ACM Certificate ARN before deploying to AWS
  certificate_arn = "arn:aws:acm:us-east-1:541495491866:certificate/12345678-1234-1234-1234-123456789012"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clinicflow_tg.arn
  }
}

# --- Compute Engine (ASG) ---
resource "aws_launch_template" "clinicflow_lt" {
  name          = "ClinicFlow-TF-Web-Template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

resource "aws_autoscaling_group" "clinicflow_asg" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  target_group_arns   = [aws_lb_target_group.clinicflow_tg.arn]

  launch_template {
    id      = aws_launch_template.clinicflow_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ClinicFlow-WebApp"
    propagate_at_launch = true
  }
}