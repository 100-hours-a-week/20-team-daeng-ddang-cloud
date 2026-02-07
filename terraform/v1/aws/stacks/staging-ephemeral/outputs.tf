output "instance_id" {
  value = module.ec2.instance_id
}

output "instance_private_dns" {
  value = module.ec2.instance_private_dns
}

output "public_ip" {
  value = module.ec2.public_ip
}

output "base_url" {
  value = "http://${module.ec2.public_ip}:${var.app_port}${var.http_base_path}"
}

output "ws_url" {
  value = "ws://${module.ec2.public_ip}:${var.app_port}${var.ws_path}"
}