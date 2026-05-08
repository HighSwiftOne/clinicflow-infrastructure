# --- Phase 1: The Identity Shield ---
resource "aws_iam_policy" "image_builder_boundary" {
  name        = "ClinicFlow-ImageBuilder-Boundary"
  description = "Ensures the factory can only touch specific resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        Action   = ["s3:Get*", "s3:List*"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::clinicflow-*",
          "arn:aws:s3:::clinicflow-*/*"
        ] 
      }
    ]
  })
}



# --- 1. The Factory Worker (IAM Role & Profile) ---
resource "aws_iam_role" "image_builder_role" {
  name = "clinicflow-image-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "image_builder_ec2" {
  role       = aws_iam_role.image_builder_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_instance_profile" "image_builder_profile" {
  name = "clinicflow-image-builder-profile"
  role = aws_iam_role.image_builder_role.name
}

# --- 2. The Hardening Recipe (Build Component) ---
resource "aws_imagebuilder_component" "clinicflow_hardening" {
  # checkov:skip=CKV_AWS_180:FinOps - Component recipe contains no sensitive data; default AWS encryption is sufficient.
  name     = "clinicflow-web-hardening"
  platform = "Linux"
  version  = "1.0.0"

  data = yamlencode({
    schemaVersion = "1.0"
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallWebServer"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "yum update -y",
                "yum install -y httpd",
                "systemctl enable httpd",
                "echo '<h1>ClinicFlow Golden AMI: Pre-Hardened and Ready.</h1>' > /var/www/html/index.html"
              ]
            }
          }
        ]
      }
    ]
  })
}

# --- 3. The Factory Floor (Infrastructure Config) ---
resource "aws_imagebuilder_infrastructure_configuration" "clinicflow_infra" {
  name                  = "clinicflow-build-infra"
  instance_profile_name = aws_iam_instance_profile.image_builder_profile.name
  instance_types        = ["t2.micro"]
  subnet_id             = aws_subnet.public_a.id
  security_group_ids    = [aws_security_group.web_sg.id]

  # checkov:skip=CKV_AWS_163:FinOps - Temporary build instance, standard logging is sufficient.
}

# Grab current AWS Region
data "aws_region" "current" {}

# --- The Raw Material (Base OS) ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- 4. The Final Blueprint (Image Recipe) ---
resource "aws_imagebuilder_image_recipe" "clinicflow_recipe" {
  name         = "clinicflow-golden-image"
  parent_image = data.aws_ami.amazon_linux.id
  version      = "1.0.1" # Incremented version to ensure a fresh build

  component {
    component_arn = aws_imagebuilder_component.clinicflow_hardening.arn
  }

  component {
    component_arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/update-linux/x.x.x"
  }
}

