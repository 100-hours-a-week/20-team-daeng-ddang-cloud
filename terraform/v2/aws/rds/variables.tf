variable "project_name" { type = string }
variable "environment" { type = string }

# Network
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# SG
variable "allowed_security_group_ids" {
  description = "RDS 접근을 허용할 SG ID 목록 (ASG SG 등)"
  type        = list(string)
  default     = []
}

# Engine
variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "15"
}

# Instance
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

# DB
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 5432
}

# HA
variable "multi_az" {
  type    = bool
  default = false
}

# Backup & Protection
variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  description = "dev: true, prod: false"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "dev: false, prod: true"
  type        = bool
  default     = false
}