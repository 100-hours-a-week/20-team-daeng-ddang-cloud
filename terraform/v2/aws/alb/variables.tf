variable "project_name" { type = string }
variable "environment" { type = string }

# Network
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }

# App
variable "be_app_port" {
  type    = number
  default = 8080
}

variable "fe_app_port" {
  type    = number
  default = 3000
}

variable "be_health_check_path" {
  type    = string
  default = "api/v3/health"
}

variable "fe_health_check_path" {
  type    = string
  default = "/health"
}

# Path 기반 라우팅
variable "be_path_patterns" {
  description = "Backend로 라우팅할 경로 패턴"
  type        = list(string)
  default     = ["/api/*"]
}