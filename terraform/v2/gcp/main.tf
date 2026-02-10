provider "google" {
  project = var.project_id
  region  = var.region
}

# 기본 Compute Engine 서비스 계정 조회
data "google_compute_default_service_account" "default" {}

# ==================== Network ====================

resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  description             = "${var.environment} 환경 VPC"
}

resource "google_compute_subnetwork" "public-subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "daenge-map-private-sbuent"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# ==================== Router / NAT ====================

resource "google_compute_router" "private_router" {
  name    = "daeng-map-private-router"
  region  = google_compute_subnetwork.private_subnet.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "daeng-map-nat" {
  name                               = "daeng-map-nat-config"
  router                             = google_compute_router.private_router.name
  region                             = google_compute_router.private_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

# ==================== Firewall ====================

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

# ==================== Static IP ====================

resource "google_compute_address" "vm_static_ip" {
  name   = "${var.environment}-vm-static-ip"
  region = var.region
}

# ==================== VM Instances ====================

resource "google_compute_instance" "vm" {
  name         = "${var.environment}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  labels       = var.labels
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public-subnet.id

    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  tags = ["ssh-enabled", "web-server", "backend-enabled", "https-developers-ip-only"]

  metadata = {
    environment = var.environment
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}

resource "google_compute_instance" "private_vm" {
  name         = "facial-expression-analysis"
  machine_type = "e2-medium"
  zone         = var.zone
  labels       = var.labels
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  tags = ["ssh-enabled"]

  metadata = {
    environment = var.environment
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

# ==================== Secret Manager ====================

resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "GEMINI_API_KEY"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "hf_token" {
  secret_id = "HF_TOKEN"

  replication {
    auto {}
  }
}

# ==================== IAM Binding ====================

resource "google_secret_manager_secret_iam_member" "gemini_api_key_access" {
  secret_id = google_secret_manager_secret.gemini_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_secret_manager_secret_iam_member" "hf_token_access" {
  secret_id = google_secret_manager_secret.hf_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}