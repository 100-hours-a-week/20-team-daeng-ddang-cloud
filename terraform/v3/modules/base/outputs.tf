output "control_plane_instance_ids" {
  value = aws_instance.control_plane[*].id
}

output "control_plane_private_ips" {
  value = aws_instance.control_plane[*].private_ip
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

output "worker_launch_template_id" {
  value = aws_launch_template.worker.id
}

output "worker_asg_name" {
  value = aws_autoscaling_group.worker.name
}

output "worker_join_ssm_parameter_name" {
  value = local.worker_join_ssm_parameter_name
}

output "control_plane_join_ssm_parameter_name" {
  value = local.control_plane_join_ssm_parameter_name
}

output "public_nlb_security_group_id" {
  value = var.envoy_public_nlb_enabled ? aws_security_group.public_nlb_sg[0].id : null
}

output "public_subnet_ids_for_elb" {
  value = var.public_subnet_ids
}