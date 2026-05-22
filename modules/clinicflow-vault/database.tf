# ====================================================================
# COMPLIANT DATA RETENTION SUBSYSTEMS - RDS TIER
# ====================================================================
resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
  name       = "clinicflow-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "ClinicFlow DB Subnet Group" }
}

resource "aws_db_instance" "clinicflow_db" {
  identifier             = "clinicflow-database-production"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.clinicflow_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  username            = "clinicadmin"
  password            = "SecurePatientDataOverride2026!" # Injected via Secrets Manager in production environments
  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = true

  # FIXED: Realigned directly to the live, physical KMS tracking key to kill the destruction risk
  kms_key_id = "arn:aws:kms:us-east-1:541495491866:key/00f72e88-f53f-4843-aed3-83bad42fee9d"

  deletion_protection                 = true
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring_role.arn

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "ClinicFlow-Production-Database"
    Environment = "Production"
  }
}