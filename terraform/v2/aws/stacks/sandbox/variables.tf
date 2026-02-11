variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = null
}

variable "project_name" {
  type    = string
  default = "daeng-map"
}

variable "environment" {
  type    = string
  default = "sandbox"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

# ===== Network =====
variable "vpc_cidr" { type = string }

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a"]
}

variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

variable "enable_nat_gw" {
  type    = bool
  default = false
}

# ===== EC2 =====
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

variable "ssh_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "app_port" {
  type    = number
  default = 8080
}