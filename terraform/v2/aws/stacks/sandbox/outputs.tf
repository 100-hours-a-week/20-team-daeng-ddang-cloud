# Network
output "vpc_id" {
  value = module.network.vpc_id
}

# EC2
output "instance_id" {
  value = aws_instance.sandbox.id
}

output "elastic_ip" {
  value = aws_eip.sandbox.public_ip
}