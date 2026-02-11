variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones (최소 2개)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (AZ 수와 동일)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (AZ 수와 동일)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "DB subnet CIDR blocks (AZ 수와 동일)"
  type        = list(string)
}

variable "enable_nat_gw" {
  description = "NAT Gateway 생성 여부 (dev: false 권장, prod: true)"
  type        = bool
  default     = true
}