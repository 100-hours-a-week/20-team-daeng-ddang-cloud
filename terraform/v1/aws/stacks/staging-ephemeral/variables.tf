variable "run_id" {
  description = "CI run identifier (e.g. github.run_id)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. staging)"
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

# network
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }

variable "ssh_ingress_cidrs" { type = list(string) }
variable "http_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "https_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "app_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# EC2
variable "key_name" {
  description = "optional. CI만 쓰면 비워도 됨"
  type        = string
  default     = ""
}
variable "instance_type" { type = string }

variable "block_device_volume_size" {
  type    = number
  default = 30
}

variable "ubuntu_ami_name_pattern" {
  type    = string
  default = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

variable "ami_id" {
  type    = string
}

# staging에서는 기본적으로 EIP 금지 (destroy 목적)
variable "use_eip" {
  type    = bool
  default = false
}

# 앱 경로
variable "http_base_path" {
  type    = string
  default = ""
}

variable "ws_path" {
  type    = string
  default = "/ws/walks"
}