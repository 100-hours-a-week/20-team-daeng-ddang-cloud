provider "aws" {
  region = var.aws_region
}

module "base" {
  source = "./modules/base"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  key_name = var.key_name

  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids


  rds_security_group_id        = var.rds_security_group_id
  elasticache_security_group_id = var.elasticache_security_group_id
  
  control_plane_ami_id = var.control_plane_ami_id
  worker_ami_id        = var.worker_ami_id

  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type

  control_plane_instance_count = var.control_plane_instance_count

  worker_asg_desired_capacity = var.worker_asg_desired_capacity
  worker_asg_min_size         = var.worker_asg_min_size
  worker_asg_max_size         = var.worker_asg_max_size

  envoy_public_nlb_enabled       = var.envoy_public_nlb_enabled
  envoy_public_nlb_ingress_cidrs = var.envoy_public_nlb_ingress_cidrs

  tags = {
    Service = "kubernetes"
  }
}
