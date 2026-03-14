provider "aws" {
  region = var.aws_region
}

module "base" {
  source = "./modules/base"

  project_name = var.project_name
  environment  = var.environment

  key_name = var.key_name

  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids

  ami_id = var.ami_id

  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type

  control_plane_instance_count = var.control_plane_instance_count
  worker_instance_count        = var.worker_instance_count

  tags = {
    Service = "kubernetes"
    Stage   = var.environment
  }
}
