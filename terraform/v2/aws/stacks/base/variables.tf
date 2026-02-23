variable "profile" {
  description = "AWS CLI profile (CI/CD에서는 null)"
  type        = string
  default     = null
}

variable "project_name" {
  type    = string
  default = "daeng-map"
}

variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

# ===== Network =====
variable "vpc_cidr" { type = string }

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "db_subnet_cidrs" { type = list(string) }

variable "enable_nat_gw" {
  type    = bool
  default = true
}

# ===== ALB =====
variable "be_app_port" {
  type    = number
  default = 8080
}

variable "fe_app_port" {
  type    = number
  default = 3000
}

variable "fe_app_port_2" {
  description = "FE 두 번째 컨테이너 포트"
  type        = number
  default     = 3001
}

variable "be_health_check_path" {
  type    = string
  default = "api/v3/health"
}

variable "fe_health_check_path" {
  type    = string
  default = "/health"
}

variable "be_path_patterns" {
  type    = list(string)
  default = ["/api/*"]
}

# ===== ASG (공통) =====
variable "key_name" {
  type    = string
  default = ""
}

variable "block_device_volume_size" {
  type    = number
  default = 30
}

variable "ssh_ingress_cidrs" {
  type    = list(string)
  default = []
}

variable "cpu_target_value" {
  type    = number
  default = 70
}

variable "monitoring_ingress_cidrs" {
  description = "Node Exporter(9100) 접근 허용 CIDR"
  type        = list(string)
  default     = []
}

# ===== BE ASG =====
variable "be_instance_type" {
  type    = string
  default = "t3.small"
}

variable "be_asg_min_size" {
  type    = number
  default = 1
}

variable "be_asg_max_size" {
  type    = number
  default = 2
}

variable "be_asg_desired_capacity" {
  type    = number
  default = 1
}

# ===== FE ASG =====
variable "fe_instance_type" {
  type    = string
  default = "t3.small"
}

variable "fe_asg_min_size" {
  type    = number
  default = 1
}

variable "fe_asg_max_size" {
  type    = number
  default = 2
}

variable "fe_asg_desired_capacity" {
  type    = number
  default = 1
}

# ===== RDS =====
variable "db_subnet_ids_override" {
  description = "기존 콘솔에서 생성한 DB Subnet Group의 서브넷 ID 목록 (지정 시 network 모듈 대신 사용)"
  type        = list(string)
  default     = []
}

variable "db_identifier" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "db_subnet_group_description" {
  type    = string
  default = "Managed by Terraform"
}

variable "rds_sg_name" {
  type = string
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "15"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_storage_encrypted" {
  type    = bool
  default = true
}

variable "db_kms_key_id" {
  description = "KMS key ARN for RDS encryption"
  type        = string
  default     = null
}

variable "db_name" {
  type    = string
  default = null
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_performance_insights_enabled" {
  type    = bool
  default = true
}

variable "db_additional_security_group_ids" {
  description = "RDS에 추가로 연결할 Security Group ID 목록"
  type        = list(string)
  default     = []
}

variable "db_existing_allowed_security_group_ids" {
  description = "RDS ingress에 추가로 허용할 기존 Security Group ID 목록 (기존 BE 서버 등)"
  type        = list(string)
  default     = []
}

# ===== ElastiCache =====
variable "redis_engine_version" {
  type    = string
  default = "7.1"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 1
}