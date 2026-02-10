output "vm_name" {
  description = "VM 이름"
  value       = google_compute_instance.vm.name
}

output "vm_internal_ip" {
  description = "내부 IP"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  description = "외부 IP"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone=${var.zone}"
}

output "web_url" {
  description = "웹 접속 URL"
  value       = "http://${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}

output "vpc_name" {
  description = "VPC 이름"
  value       = google_compute_network.vpc.name
}

output "subnet_cidr" {
  description = "서브넷 CIDR"
  value       = google_compute_subnetwork.public-subnet.ip_cidr_range
}

output "gemini_api_key_secret_id" {
  description = "GEMINI_API_KEY Secret ID"
  value       = google_secret_manager_secret.gemini_api_key.id
}

output "hf_token_secret_id" {
  description = "HF_TOKEN Secret ID"
  value       = google_secret_manager_secret.hf_token.id
}

output "service_account_email" {
  description = "Secret에 접근 가능한 서비스 계정"
  value       = data.google_compute_default_service_account.default.email
}