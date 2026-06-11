# ====================================================================
# COMPLIANT DATA RETENTION SUBSYSTEMS - RDS TIER
# ====================================================================
resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
  name = "clinicflow-db-subnet-group"

  # Dynamic referencing replaces hardcoded strings
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "ClinicFlow DB Subnet Group"
  }
}

resource "aws_db_instance" "clinicflow_db" {
  identifier           = "clinicflow-database-production"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true
  db_subnet_group_name = aws_db_subnet_group.clinicflow_db_subnet_group.name

  # Hardened to the true live physical control plane ID
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  username = "clinicadmin"
  # ELITE GUARDRAIL: AWS natively manages and rotates the password via Secrets Manager
  manage_master_user_password = true

  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = true

  kms_key_id = "arn:aws:kms:us-east-1:541495491866:key/00f72e88-f53f-4843-aed3-83bad42fee9d"

  deletion_protection                 = true
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  # Log Stream Exports and Enhanced Telemetry
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring_role.arn

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "ClinicFlow-Production-Database"
    Environment = "Production"
  }
}

# ====================================================================
# ENHANCED MONITORING TELEMETRY TRUST IDENTITY
# ====================================================================
resource "aws_iam_role" "rds_monitoring_role" {
  name = "ClinicFlow-RDS-Enhanced-Monitoring-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}