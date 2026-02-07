variable "project_name" { type = string }
variable "environment" { type = string }

variable "subnet_id" { type = string }
variable "sg_id" { type = string }

variable "key_name" {
  description = "EC2 key pair name (optional)"
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
  description = "Custom AMI ID (if empty, uses latest Ubuntu)"
  type        = string
  default     = ""
}

# EIP 옵션화 (staging-ephemeral에서는 false 권장)
variable "use_eip" {
  type    = bool
  default = false
}
