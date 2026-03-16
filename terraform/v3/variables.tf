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

variable "control_plane_ami_id" {
  type = string
}

variable "worker_ami_id" {
  type = string
}

variable "control_plane_instance_count" {
  description = "Number of control plane instances"
  type        = number
  default     = 3
}

variable "worker_asg_desired_capacity" {
  description = "Number of worker desired capacity"
  type        = number
  default     = 0
}

variable "worker_asg_min_size" {
  description = "Number of worker min size"
  type        = number
  default     = 0
}

variable "worker_asg_max_size" {
  description = "Number of worker max size"
  type        = number
  default     = 9
}

variable "envoy_public_nlb_enabled" {
  type    = bool
  default = true
}

variable "envoy_public_nlb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}