# ─── Master Nodes ─────────────────────────────────────────────

output "master_private_ips" {
  description = "Master 노드 Private IP 목록"
  value       = aws_instance.master[*].private_ip
}

output "master_public_ips" {
  description = "Master 노드 Public IP 목록 (있을 경우)"
  value       = aws_instance.master[*].public_ip
}

output "master_instance_ids" {
  description = "Master 노드 인스턴스 ID 목록"
  value       = aws_instance.master[*].id
}

# ─── Worker Nodes ─────────────────────────────────────────────

output "worker_private_ips" {
  description = "Worker 노드 Private IP 목록"
  value       = aws_instance.worker[*].private_ip
}

output "worker_public_ips" {
  description = "Worker 노드 Public IP 목록 (있을 경우)"
  value       = aws_instance.worker[*].public_ip
}

output "worker_instance_ids" {
  description = "Worker 노드 인스턴스 ID 목록"
  value       = aws_instance.worker[*].id
}

# ─── NLB ──────────────────────────────────────────────────────

output "k8s_api_nlb_dns" {
  description = "K8s API Server NLB DNS 이름"
  value       = aws_lb.k8s_api.dns_name
}
