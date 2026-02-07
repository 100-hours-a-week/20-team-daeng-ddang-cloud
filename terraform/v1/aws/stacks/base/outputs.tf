output "vpc_id" {
  value = module.base_network.vpc_id
}

output "public_subnet_id" {
  value = module.base_network.public_subnet_id
}

output "ec2_sg_id" {
  value = module.base_network.ec2_sg_id
}

output "bucket_name" {
  value = var.enable_s3 ? module.s3[0].bucket_name : null
}

output "bucket_arn" {
  value = length(module.s3) > 0 ? module.s3[0].bucket_arn : null
}
