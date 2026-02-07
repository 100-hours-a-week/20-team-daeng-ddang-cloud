module "network" {
  source = "../../modules/base_network"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr           = var.vpc_cidr
  az                 = var.az
  public_subnet_cidr = var.public_subnet_cidr

  ssh_ingress_cidrs   = var.ssh_ingress_cidrs
  http_ingress_cidrs  = var.http_ingress_cidrs
  https_ingress_cidrs = var.https_ingress_cidrs
}

resource "aws_security_group_rule" "app_ingress" {
  type              = "ingress"
  security_group_id = module.network.ec2_sg_id

  from_port   = var.app_port
  to_port     = var.app_port
  protocol    = "tcp"
  cidr_blocks = var.app_ingress_cidrs

  description = "App ingress for load test"
}

module "ec2" {
  source = "../../modules/ec2_single"

  project_name = var.project_name
  environment  = var.environment

  subnet_id = module.network.public_subnet_id
  sg_id     = module.network.ec2_sg_id

  key_name      = var.key_name
  instance_type = var.instance_type

  block_device_volume_size = var.block_device_volume_size
  ubuntu_ami_name_pattern  = var.ubuntu_ami_name_pattern
  ami_id                   = var.ami_id

  use_eip = var.use_eip
}