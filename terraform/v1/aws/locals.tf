locals {
  common_tags = {
    terraform = "true"
    env       = var.environment
    project   = var.project_name
  }
}