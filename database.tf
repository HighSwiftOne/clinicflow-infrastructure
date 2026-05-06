# ==============================================================================
# 1. THE VAULT LOCATION (DB SUBNET GROUP)
# ==============================================================================

# We have to explicitly tell AWS to put this database in our Private Subnets,
# otherwise it might try to deploy it in the default public subnets.
resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
  name       = "clinicflow-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "ClinicFlow-DB-Subnet-Group"
  }
}

# ==============================================================================
# 2. THE CORE ASSET (MULTI-AZ RDS DATABASE)
# ==============================================================================

resource "aws_db_instance" "clinicflow_db" {
  identifier           = "clinicflow-database-production"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  # The Master Credentials (In a real production DevSecOps pipeline, 
  # these would be dynamically injected by AWS Secrets Manager, not hardcoded).
  username             = "clinicadmin"
  password             = "SuperSecretPassword123!" 
  
  # The High Availability Switch (Synchronous Standby in AZ-B)
  multi_az             = true

  # The Zero-Trust Network Placements
  db_subnet_group_name   = aws_db_subnet_group.clinicflow_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  # Hafner's Rule: The absolute guarantee that it has no path to the internet.
  publicly_accessible    = false
  
  # Skip final snapshot so we can easily destroy this lab environment later
  skip_final_snapshot    = true

  tags = {
    Name = "ClinicFlow-Production-DB"
  }
}
