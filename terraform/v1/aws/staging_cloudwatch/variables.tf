variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment tag to filter instances"
  type        = string
  default     = "staging"
}

