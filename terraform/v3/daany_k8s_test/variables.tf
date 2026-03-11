variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "daeng-map"
}

variable "environment" {
  description = "환경 (prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "profile" {
  description = "AWS CLI 프로파일"
  type        = string
  default     = null
}

# ─── 기존 VPC / Subnet ────────────────────────────────────────

variable "vpc_id" {
  description = "기존 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "EC2를 배포할 서브넷 ID 목록 (AZ 분산용)"
  type        = list(string)
}

# ─── EC2 공통 ─────────────────────────────────────────────────

variable "key_name" {
  description = "SSH 키페어 이름"
  type        = string
  default     = "daeng-map-keypair"
}

variable "block_device_volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

variable "ssh_ingress_cidrs" {
  description = "SSH 접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ─── Master 노드 ─────────────────────────────────────────────

variable "master_instance_type" {
  description = "마스터 노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "master_count" {
  description = "마스터 노드 수"
  type        = number
  default     = 3
}

# ─── Worker 노드 ─────────────────────────────────────────────

variable "worker_instance_type" {
  description = "워커 노드 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "워커 노드 수"
  type        = number
  default     = 3
}
