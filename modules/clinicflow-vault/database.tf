# ====================================================================
# COMPLIANT DATA RETENTION SUBSYSTEMS - RDS TIER
# ====================================================================
resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
  name       = "clinicflow-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "ClinicFlow DB Subnet Group"
  }
}

resource "aws_db_instance" "clinicflow_db" {
  identifier             = "clinicflow-database-production"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.clinicflow_cmk.arn
  db_subnet_group_name   = aws_db_subnet_group.clinicflow_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  username            = "clinicadmin"
  password            = "SecurePatientDataOverride2026!" # Ensure this is injected securely via secrets manager in prod
  skip_final_snapshot = true
  publicly_accessible = false

  # UNCOMPROMISED ARCHITECTURE PILLAR: High-Availability Failover Datacenter Active
  multi_az = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "ClinicFlow-Production-Database"
    Environment = "Production"
  }
}