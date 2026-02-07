output "instance_id" {
  value = aws_instance.server.id
}

output "instance_private_dns" {
  value = aws_instance.server.private_dns
}

output "public_ip" {
  # EIP를 쓰면 EIP, 아니면 인스턴스 퍼블릭 IP
  value = var.use_eip ? aws_eip.server[0].public_ip : aws_instance.server.public_ip
}

output "public_dns" {
  value = aws_instance.server.public_dns
}

output "private_ip" {
  value = aws_instance.server.private_ip
}