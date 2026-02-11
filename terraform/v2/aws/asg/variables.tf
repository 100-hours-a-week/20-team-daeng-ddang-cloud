variable "project_name" { type = string }
variable "environment" { type = string }

# Network
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# ALB
variable "alb_sg_id" { type = string }
variable "target_group_arns" { type = list(string) }

# Instance
variable "ami_id" { type = string }

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "block_device_volume_size" {
  type    = number
  default = 30
}

# App
variable "app_port" {
  type    = number
  default = 8080
}

variable "ssh_ingress_cidrs" {
  type    = list(string)
  default = []
}

variable "monitoring_ingress_cidrs" {
  description = "Node Exporter(9100) 접근 허용 CIDR"
  type        = list(string)
  default     = []
}

# User Data
variable "user_data" {
  description = "Base64 인코딩된 사용자 스크립트"
  type        = string
  default     = null
}

# Scaling
variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "cpu_target_value" {
  description = "CPU 목표 사용률 (%)"
  type        = number
  default     = 70
}