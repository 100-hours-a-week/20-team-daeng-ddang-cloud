variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "daeng-map"
}

variable "region" {
  description = "Value of region"
  type        = string
  default     = "ap-northeast-2"
}

variable "az" {
  description = "Availability zone"
  type        = string
  default     = "ap-northeast-2a"
}

# ==== Network ====
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
}

# ==== EC2 ====
variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "block_device_volume_size" {
  description = "Root EBS volume size (GiB)"
  type        = number
  default     = 30
}

variable "ubuntu_ami_name_pattern" {
  description = "Ubuntu AMI name pattern"
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

# ==== Security Group ingress ====
variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
}

variable "http_ingress_cidrs" {
  description = "CIDR blocks allowed to HTTP (80)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_ingress_cidrs" {
  description = "CIDR blocks allowed to HTTPS (443)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ==== S3 ====
variable "s3_cors_allowed_origins" {
  description = "S3 CORS allowed origins"
  type        = list(string)
}

variable "s3_cors_allowed_methods" {
  description = "S3 CORS allowed methods"
  type        = list(string)
  default     = ["GET", "HEAD", "PUT", "POST", "DELETE"]
}

variable "s3_cors_allowed_headers" {
  description = "S3 CORS allowed headers"
  type        = list(string)
  default     = ["*"]
}

variable "s3_cors_expose_headers" {
  description = "S3 CORS expose headers"
  type        = list(string)
  default     = ["ETag"]
}

variable "s3_cors_max_age_seconds" {
  description = "S3 CORS max age seconds"
  type        = number
  default     = 3000
}