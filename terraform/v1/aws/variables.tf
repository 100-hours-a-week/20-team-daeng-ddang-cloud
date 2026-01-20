variable "environment" {
  description = "Value of Environment"
  type        = string
  default     = "dev"
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
  description = "Value of AZ"
  type        = string
  default     = "ap-northeast-2a"
}

variable "key_name" {
  description = "EC2 SSH Keypair name"
  type        = string
  default     = "daeng-map-keypair"
}

variable "instance_type" {
  description = "The EC2 instance's type"
  type        = string
  default     = "t3.micro"
}