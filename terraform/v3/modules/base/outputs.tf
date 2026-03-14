output "control_plane_instance_ids" {
  value = aws_instance.control_plane[*].id
}

output "control_plane_private_ips" {
  value = aws_instance.control_plane[*].private_ip
}

output "worker_instance_ids" {
  value = aws_instance.worker[*].id
}

output "worker_private_ips" {
  value = aws_instance.worker[*].private_ip
}

output "control_plane_security_group_id" {
  value = aws_security_group.control_plane_sg.id
}

output "worker_security_group_id" {
  value = aws_security_group.worker_sg.id
}

output "kube_apiserver_internal_nlb_dns_name" {
  value = aws_lb.kube_apiserver_internal.dns_name
}

output "kube_apiserver_target_group_arn" {
  value = aws_lb_target_group.kube_apiserver_tg.arn
}