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

# Network
variable "vpc_cidr" { type = string }

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

variable "enable_nat_gw" {
  type    = bool
  default = true
}