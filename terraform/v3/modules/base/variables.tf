variable "project_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name such as prod or dev"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

# ==== VPC ====

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the existing VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs"
  type        = list(string)
}

# ==== EC2 ====

variable "control_plane_instance_count" {
  description = "Number of control plane instances"
  type        = number
  default     = 3
}

variable "worker_asg_desired_capacity" {
  description = "Number of worker desired capacity"
  type        = number
}

variable "worker_asg_min_size" {
  description = "Number of worker min size"
  type        = number
}

variable "worker_asg_max_size" {
  description = "Number of worker max size"
  type        = number
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for control planes"
  type        = string
}

variable "worker_instance_type" {
  description = "EC2 instance type for workers"
  type        = string
}

variable "control_plane_ami_id" {
  description = "AMI ID for all control plane nodes"
  type        = string
}

variable "worker_ami_id" {
  description = "AMI ID for all worker nodes"
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name"
  type        = string
  default     = null
}

variable "control_plane_root_volume_type" {
  description = "Root volume type for control plane nodes"
  type        = string
  default     = "gp3"
}

variable "worker_root_volume_type" {
  description = "Root volume type for control plane nodes"
  type        = string
  default     = "gp3"
}

variable "control_plane_root_volume_size" {
  description = "Root volume size for control plane nodes"
  type        = number
  default     = 30
}

variable "worker_root_volume_size" {
  description = "Root volume size for worker nodes"
  type        = number
  default     = 30
}

variable "node_additional_security_group_ids" {
  description = "Additional security groups to attach to nodes"
  type        = list(string)
  default     = []
}

variable "enable_ssm" {
  description = "Whether to attach SSM managed policy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "envoy_public_nlb_enabled" {
  description = "Whether to prepare AWS networking resources for Envoy Gateway public NLB"
  type        = bool
  default     = true
}

variable "envoy_public_nlb_ingress_cidrs" {
  description = "CIDRs allowed to access Envoy Gateway public NLB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}