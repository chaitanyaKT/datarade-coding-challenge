resource "aws_db_instance" "dr_cc_pg_db" {
  identifier = "dr-cc-pg-db"
  db_name    = "dr_cc_pg_db"

  allocated_storage     = 20
  max_allocated_storage = 100

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  username                    = "postgres"
  manage_master_user_password = true

  multi_az                 = false #Set to false as this is for testing. In production, should be set to true.
  delete_automated_backups = true  #Set to true as this is for testing. In production, should be set to false.
  skip_final_snapshot      = true  #Set to true as this is for testing. In production, should be set to false.

  port                   = 9876
  storage_encrypted      = true
  storage_type           = "gp2" #Depending on the usecase, we could set this to iops in production
  vpc_security_group_ids = [module.db_sg.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.dr_cc_db_sn.name

  tags = {
    Terraform   = true
    Environment = "dr-cc-dev"
  }

  # kms_key_id = "" #For encryption.
  # monitoring_interval = 30 #Enhanced monitoring metrics collected every 30 sec.
  # performance_insights_enables = true
  # performance_insights_retention_period = 180
  # maintenance_window = "ddd:hh24:mi-ddd:hh24:mi"
  # final_snapshot_identifier = "dr_cg_pg_db_final_snap"
  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  # deletion_protection = true
}

output "pg_db_secret" {
  description = "Secret for PG DB"
  value       = aws_db_instance.dr_cc_pg_db.master_user_secret
}

output "DB_HOST" {
  description = "PG DB Host"
  value       = aws_db_instance.dr_cc_pg_db.address
}

output "DB_PORT" {
  description = "PG DB Port"
  value       = aws_db_instance.dr_cc_pg_db.port
}

output "DB_NAME" {
  description = "PG DB Name"
  value       = aws_db_instance.dr_cc_pg_db.db_name
}