##############################
# DB Subnet Group
##############################
resource "aws_db_subnet_group" "main" {
  name        = var.db_subnet_group_name
  description = var.db_subnet_group_description
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = var.db_subnet_group_name
  }
}

##############################
# Security Group
##############################
resource "aws_security_group" "rds" {
  name        = var.rds_sg_name
  description = var.rds_sg_name
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.rds_sg_name
  }
}

##############################
# RDS Instance
##############################
resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_name                    = var.db_name
  username                   = var.db_username
  manage_master_user_password = true
  port                       = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = concat([aws_security_group.rds.id], var.additional_security_group_ids)

  multi_az            = var.multi_az
  availability_zone   = var.multi_az ? null : var.availability_zone
  publicly_accessible = false

  performance_insights_enabled = var.performance_insights_enabled

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  tags = {
    Name = var.db_identifier
  }
}