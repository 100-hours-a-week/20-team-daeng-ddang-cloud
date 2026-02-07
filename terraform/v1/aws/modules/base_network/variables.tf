variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_cidr" { type = string }

variable "az" {
  description = "Availability zone for the public subnet"
  type        = string
}

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

# 권장: 퍼블릭 서브넷에서 퍼블릭 IP 자동 할당
variable "public_subnet_map_public_ip_on_launch" {
  type    = bool
  default = true
}
