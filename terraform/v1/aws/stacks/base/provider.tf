provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      terraform = "true"
      env       = var.environment
      project   = var.project_name
    }
  }
}
