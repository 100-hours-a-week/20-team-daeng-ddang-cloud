output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "instance_hostname" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.server.private_dns
}