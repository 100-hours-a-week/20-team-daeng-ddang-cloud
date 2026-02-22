variable "project_name" { type = string }
variable "environment" { type = string }

# Network
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# Naming
variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_subnet_group_name" {
  description = "DB Subnet Group name"
  type        = string
}

variable "db_subnet_group_description" {
  description = "DB Subnet Group description"
  type        = string
  default     = "Managed by Terraform"
}

variable "rds_sg_name" {
  description = "RDS Security Group name"
  type        = string
}

# SG
variable "allowed_security_group_ids" {
  description = "RDS 접근을 허용할 SG ID 목록 (ASG SG 등)"
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "RDS에 추가로 연결할 Security Group ID 목록"
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
variable "db_name" {
  type    = string
  default = null
}
variable "db_username" { type = string }

variable "db_port" {
  type    = number
  default = 5432
}

# Encryption
variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "kms_key_id" {
  description = "KMS key ARN for RDS encryption"
  type        = string
  default     = null
}

# Performance Insights
variable "performance_insights_enabled" {
  type    = bool
  default = true
}

# HA
variable "multi_az" {
  type    = bool
  default = false
}

variable "availability_zone" {
  description = "Single AZ 배치 시 사용할 가용 영역"
  type        = string
  default     = null
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