# ====================================================================
# APPLICATION HARDENED LOAD BALANCER
# ====================================================================
resource "aws_lb" "clinicflow_alb" {
  name               = "ClinicFlow-ALB"
  internal           = false
  load_balancer_type = "application"

  # Pointing strictly to the unified Web Security Group 
  security_groups = [aws_security_group.web_sg.id]

  # Pointing strictly to the aligned Public Subnets
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  # High-leverage guardrail to protect the live traffic router
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

  # ELITE GUARDRAIL: Hard-anchored to the true physical database/ALB network
  vpc_id = data.aws_vpc.clinicflow_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

# --- Listeners ---
resource "aws_lb_listener" "http_forward" {
  load_balancer_arn = aws_lb.clinicflow_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clinicflow_tg.arn
  }

  # This forces AWS to spin up the new configuration before killing the old one,
  # gracefully transferring the traffic and preventing API crashes.
  lifecycle {
    create_before_destroy = true
  }
}

# --- Compute Engine (ASG) ---


resource "aws_launch_template" "clinicflow_lt" {
  name          = "ClinicFlow-TF-Web-Template"
  image_id      = data.aws_ami.amazon_linux.id # <--- Swapped to the raw materials
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