variable "project_name" { type = string }
variable "environment" { type = string }

# Network
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# SG
variable "allowed_security_group_ids" {
  description = "Redis 접근을 허용할 SG ID 목록 (ASG SG 등)"
  type        = list(string)
  default     = []
}

# Redis
variable "engine_version" {
  type    = string
  default = "7.1"
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "num_cache_clusters" {
  description = "dev: 1, prod: 2"
  type        = number
  default     = 1
}

variable "transit_encryption_enabled" {
  description = "redis 네트워크로 오가는 데이터(TLS) 보호"
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "redis 저장되는 데이터(백업/스냅샷/디스크) 보호"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "redis 비밀번호"
  type        = string
  default     = "ROTATE"
}

variable "auth_token_update_strategy" {
  description = "redis 토큰 변경"
  type        = string
  default     = null
}

variable "parameter_group_name" {
  type    = string
  default = "default.redis7"
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "preferred_cache_cluster_azs" {
  description = "캐시 클러스터 배치 가용 영역"
  type        = list(string)
  default     = null
}
