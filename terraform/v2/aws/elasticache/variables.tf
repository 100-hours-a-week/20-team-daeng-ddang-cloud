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