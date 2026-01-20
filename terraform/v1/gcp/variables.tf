# 필수 변수
variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "asia-northeast3-b"
}

# 환경 변수
variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# VM 변수
variable "machine_type" {
  description = "VM 머신 타입"
  type        = string
  default     = "n1-standard-1"
}

variable "boot_image" {
  description = "부팅 이미지"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size_gb" {
  description = "디스크 크기 (GB)"
  type        = number
  default     = 20
}

# 네트워크 변수
variable "subnet_cidr" {
  description = "서브넷 CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

# 라벨
variable "labels" {
  description = "리소스 라벨"
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}