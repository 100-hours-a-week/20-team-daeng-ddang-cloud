##############################
# Ubuntu 24.04 AMI
##############################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "network" {
  source = "../../network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  enable_nat_gw        = var.enable_nat_gw
}

module "alb" {
  source = "../../alb"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids

  be_app_port          = var.be_app_port
  fe_app_port          = var.fe_app_port
  fe_app_port_2        = var.fe_app_port_2
  be_health_check_path = var.be_health_check_path
  fe_health_check_path = var.fe_health_check_path
  be_path_patterns     = var.be_path_patterns
}

module "be_asg" {
  source = "../../asg"

  project_name       = "${var.project_name}-be"
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = [module.network.private_subnet_ids[0]]

  alb_sg_id         = module.alb.alb_sg_id
  target_group_arns = [module.alb.be_target_group_arn]

  ami_id                   = data.aws_ami.ubuntu.id
  instance_type            = var.be_instance_type
  key_name                 = var.key_name
  block_device_volume_size = var.block_device_volume_size
  app_port                 = var.be_app_port
  ssh_ingress_cidrs        = var.ssh_ingress_cidrs
  monitoring_ingress_cidrs = var.monitoring_ingress_cidrs
  user_data                = base64encode(file("${path.module}/scripts/user_data.sh"))

  min_size         = var.be_asg_min_size
  max_size         = var.be_asg_max_size
  desired_capacity = var.be_asg_desired_capacity
  cpu_target_value = var.cpu_target_value
}

module "fe_asg" {
  source = "../../asg"

  project_name       = "${var.project_name}-fe"
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = [module.network.private_subnet_ids[0]]

  alb_sg_id         = module.alb.alb_sg_id
  target_group_arns = [module.alb.fe_target_group_arn, module.alb.fe_target_group_2_arn]

  ami_id                   = data.aws_ami.ubuntu.id
  instance_type            = var.fe_instance_type
  key_name                 = var.key_name
  block_device_volume_size = var.block_device_volume_size
  app_port                 = var.fe_app_port
  additional_app_ports     = [var.fe_app_port_2]
  ssh_ingress_cidrs        = var.ssh_ingress_cidrs
  monitoring_ingress_cidrs = var.monitoring_ingress_cidrs
  user_data                = base64encode(file("${path.module}/scripts/user_data.sh"))

  min_size         = var.fe_asg_min_size
  max_size         = var.fe_asg_max_size
  desired_capacity = var.fe_asg_desired_capacity
  cpu_target_value = var.cpu_target_value
}

module "rds" {
  source = "../../rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = length(var.db_subnet_ids_override) > 0 ? var.db_subnet_ids_override : module.network.db_subnet_ids

  db_identifier               = var.db_identifier
  db_subnet_group_name        = var.db_subnet_group_name
  db_subnet_group_description = var.db_subnet_group_description
  rds_sg_name                 = var.rds_sg_name

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = var.db_storage_encrypted
  kms_key_id            = var.db_kms_key_id

  db_name     = var.db_name
  db_username = var.db_username

  multi_az            = var.db_multi_az
  availability_zone   = var.azs[0]
  skip_final_snapshot = var.db_skip_final_snapshot
  deletion_protection = var.db_deletion_protection

  performance_insights_enabled = var.db_performance_insights_enabled

  allowed_security_group_ids    = concat([module.be_asg.asg_sg_id], var.db_existing_allowed_security_group_ids)
  additional_security_group_ids = var.db_additional_security_group_ids
}

module "elasticache" {
  source = "../../elasticache"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = length(var.db_subnet_ids_override) > 0 ? var.db_subnet_ids_override : module.network.db_subnet_ids

  engine_version                  = var.redis_engine_version
  node_type                       = var.redis_node_type
  num_cache_clusters              = var.redis_num_cache_clusters
  preferred_cache_cluster_azs     = [var.azs[0]]

  allowed_security_group_ids = [module.be_asg.asg_sg_id]
}