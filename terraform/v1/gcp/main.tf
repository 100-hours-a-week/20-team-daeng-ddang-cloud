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

# 서브넷
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
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


# VM 생성
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
    subnetwork = google_compute_subnetwork.subnet.id

    # 외부 IP 할당
    access_config {
      # 비워두면 임시 외부 IP 자동 할당
    }
  }

  # 방화벽 태그
  tags = ["ssh-enabled", "web-server"]

  
  metadata = {
    environment = var.environment
  }
}