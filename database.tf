# 1. Grab your dynamic AWS Account ID
data "aws_caller_identity" "current" {}

# 2. The KMS Padlock (Encryption at Rest)
resource "aws_kms_key" "clinicflow_db_key" {
  description             = "KMS key for ClinicFlow RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "ClinicFlow-KMS"
  }
}

# 3. The Strict KMS Policy (Who holds the key)
resource "aws_kms_key_policy" "clinicflow_db_key_policy" {
  key_id = aws_kms_key.clinicflow_db_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# 4. The Private Subnet Routing
resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
  name       = "clinicflow-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "ClinicFlow DB Subnet Group"
  }
}
# checkov:skip=CKV_AWS_293:Lab Environment - Deletion protection blocks 'terraform destroy'.
# checkov:skip=CKV_AWS_118:FinOps - Enhanced monitoring incurs additional CloudWatch costs.

# 5. The MedSpa Data Vault
resource "aws_db_instance" "clinicflow_db" {
  identifier           = "clinicflow-database-production"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  username             = "clinicadmin"
  password             = "SuperSecretPassword123!" 
  
  multi_az             = true
  
  db_subnet_group_name   = aws_db_subnet_group.clinicflow_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  publicly_accessible    = false
  skip_final_snapshot    = true
  
enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # --- THE HIPAA UPGRADES ---
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.clinicflow_db_key.arn
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  tags = {
    Name = "ClinicFlow-Production-DB"
  }
}