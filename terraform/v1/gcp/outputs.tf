
# VM 정보 출력
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

# SSH 접속 명령어
output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone=${var.zone}"
}

# 웹 접속 URL
output "web_url" {
  description = "웹 접속 URL"
  value       = "http://${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}

# 네트워크 정보
output "vpc_name" {
  description = "VPC 이름"
  value       = google_compute_network.vpc.name
}

output "subnet_cidr" {
  description = "서브넷 CIDR"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}