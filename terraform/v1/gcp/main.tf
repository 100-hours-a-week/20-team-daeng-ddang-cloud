# Provider 설정
provider "google" {
  project = var.project_id
  region  = var.region
}


# VPC 네트워크
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  description             = "${var.environment} 환경 VPC"
}


# 리소스 이름 변경 (subnet → public_subnet)
moved {
  from = google_compute_subnetwork.subnet
  to   = google_compute_subnetwork.public-subnet
}

# 서브넷
resource "google_compute_subnetwork" "public-subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name    = "daenge-map-private-sbuent"
  ip_cidr_range = "10.0.2.0/24"
  region = var.region
  network = google_compute_network.vpc.id

  # 외부 IP없이 Google API에 접근 가능하게 설정
  private_ip_google_access = true
}

# Cloud Router 생성
resource "google_compute_router" "private_router" {
  name    = "daeng-map-private-router"
  region = google_compute_subnetwork.private_subnet.region
  network = google_compute_network.vpc.id
}

# Cloud NAT 생성
resource "google_compute_router_nat" "daeng-map-nat" {
  name                               = "daeng-map-nat-config"
  router                             = google_compute_router.private_router.name
  region = google_compute_router.private_router.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

# SSH 허용 (22번 포트)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

# HTTP/HTTPS 허용 (웹서버용)
resource "google_compute_firewall" "allow_http" {
  name    = "${var.environment}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# 내부 통신 허용
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}


# 기존 고정 IP import
import {
  id = "projects/project-53832a4d-3a07-4eee-969/regions/asia-northeast3/addresses/ai"
  to = google_compute_address.vm_static_ip
}

# 고정 외부 IP
resource "google_compute_address" "vm_static_ip" {
  name   = "${var.environment}-vm-static-ip"
  region = var.region
}

# public subnet에 VM 생성
resource "google_compute_instance" "vm" {
  name         = "${var.environment}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  labels       = var.labels

  # 부팅 디스크
  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  # 네트워크 설정
  network_interface {
    subnetwork = google_compute_subnetwork.public-subnet.id

    # 고정 외부 IP 할당
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  # 방화벽 태그 (기존 태그 유지)
  tags = ["ssh-enabled", "web-server", "backend-enabled", "https-developers-ip-only"]

  metadata = {
    environment = var.environment
  }

  # 기존 SSH 키 변경 방지
  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}

# private subnet에 VM 생성
resource "google_compute_instance" "private_vm" {
  name         = "facial-expression-analysis"
  machine_type = "e2-medium"
  zone         = var.zone
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # private subnet이므로 외부 IP 없음 (NAT를 통해 외부 접근)
  }

  # 방화벽 태그 (내부 통신 + SSH via IAP)
  tags = ["ssh-enabled"]

  metadata = {
    environment = var.environment
  }
}

# private subnet에 AI 분석용 VM 생성 (vCPU 4, RAM 8GB)
resource "google_compute_instance" "ai_vm" {
  name         = "ai-analysis-vm"
  machine_type = "e2-custom-4-8192"  # vCPU 4, RAM 8GB
  zone         = var.zone
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # private subnet이므로 외부 IP 없음 (NAT를 통해 외부 접근)
  }

  # 방화벽 태그
  tags = ["ssh-enabled"]

  metadata = {
    environment = var.environment
  }
}