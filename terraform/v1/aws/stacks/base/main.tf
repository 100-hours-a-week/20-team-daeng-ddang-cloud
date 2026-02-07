module "base_network" {
  source = "../../modules/base_network"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr           = var.vpc_cidr
  az                 = var.az
  public_subnet_cidr = var.public_subnet_cidr

  ssh_ingress_cidrs   = var.ssh_ingress_cidrs
  http_ingress_cidrs  = var.http_ingress_cidrs
  https_ingress_cidrs = var.https_ingress_cidrs

  # 퍼블릭 서브넷이면 true 권장
  public_subnet_map_public_ip_on_launch = true
}

module "s3" {
  count  = var.enable_s3 ? 1 : 0
  source = "../../modules/s3_public_bucket"

  project_name = var.project_name
  environment  = var.environment
  bucket_name  = var.bucket_name

  s3_cors_allowed_origins = var.s3_cors_allowed_origins
  s3_cors_allowed_methods = var.s3_cors_allowed_methods
  s3_cors_allowed_headers = var.s3_cors_allowed_headers
  s3_cors_expose_headers  = var.s3_cors_expose_headers
  s3_cors_max_age_seconds = var.s3_cors_max_age_seconds
}
