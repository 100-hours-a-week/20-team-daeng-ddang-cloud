# Network
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "db_subnet_ids" {
  value = module.network.db_subnet_ids
}

# ALB
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

# ASG
output "be_asg_name" {
  value = module.be_asg.asg_name
}

output "fe_asg_name" {
  value = module.fe_asg.asg_name
}

# RDS
output "db_endpoint" {
  value = module.rds.db_endpoint
}

# ElastiCache
output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}