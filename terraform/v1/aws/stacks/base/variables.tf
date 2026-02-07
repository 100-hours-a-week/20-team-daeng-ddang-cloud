variable "profile" {
  description = "로컬에서만 쓰는 AWS profile (CI/CD에서는 null)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g. base)"
  type        = string
}

variable "project_name" {
  type    = string
  default = "daeng-map"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "az" {
  type    = string
  default = "ap-northeast-2a"
}

# Network
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }

# SG ingress
variable "ssh_ingress_cidrs" { type = list(string) }
variable "http_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "https_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# S3 (base에 둘지 말지 선택)
variable "enable_s3" {
  type    = bool
  default = true
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "daeng-map"
}

variable "s3_cors_allowed_origins" {
  type    = list(string)
  default = []
}

variable "s3_cors_allowed_methods" {
  type    = list(string)
  default = ["GET", "HEAD", "PUT", "POST", "DELETE"]
}
variable "s3_cors_allowed_headers" {
  type    = list(string)
  default = ["*"]
}
variable "s3_cors_expose_headers" {
  type    = list(string)
  default = ["ETag"]
}
variable "s3_cors_max_age_seconds" {
  type    = number
  default = 3000
}
