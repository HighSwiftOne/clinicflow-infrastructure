# ==============================================================================
# 1. THE TRAFFIC COP (APPLICATION LOAD BALANCER)
# ==============================================================================

resource "aws_lb" "clinicflow_alb" {
  name               = "ClinicFlow-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "ClinicFlow-ALB"
  }
}

resource "aws_lb_target_group" "clinicflow_tg" {
  name     = "ClinicFlow-TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.clinicflow_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.clinicflow_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clinicflow_tg.arn
  }
}

# ==============================================================================
# 2. THE GOLDEN IMAGE LOOKUP (DEVSECOPS PREP)
# ==============================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ==============================================================================
# 3. THE BLUEPRINT (LAUNCH TEMPLATE)
# ==============================================================================

resource "aws_launch_template" "clinicflow_lt" {
  name          = "ClinicFlow-TF-Web-Template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-USERDATA
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>ClinicFlow Portal: Handled by Terraform ASG Fleet. HIPAA Engine Online.</h1>" > /var/www/html/index.html
              USERDATA
  )
}

# ==============================================================================
# 4. THE ROBOTIC MANAGER (AUTO SCALING GROUP)
# ==============================================================================

resource "aws_autoscaling_group" "clinicflow_asg" {
  name                = "ClinicFlow-ASG"
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  target_group_arns   = [aws_lb_target_group.clinicflow_tg.arn]
  
  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  launch_template {
    id      = aws_launch_template.clinicflow_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ClinicFlow-ASG-Fleet"
    propagate_at_launch = true
  }
}
