variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "daeng-map"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "profile" {
  description = "AWS CLI 프로파일"
  type        = string
  default     = null
}

# ==== VPC ====

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

# ==== EC2 공통 ====

variable "ami_id" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "control_plane_instance_type" {
  type = string
}

variable "worker_instance_type" {
  type = string
}

variable "control_plane_instance_count" {
  description = "Number of control plane instances"
  type        = number
  default     = 3
}

variable "worker_instance_count" {
  description = "Number of worker instances"
  type        = number
  default     = 2
}

