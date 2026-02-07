provider "aws" {
  region = var.region

  default_tags {
    tags = {
      terraform = "true"
      env       = var.environment
      project   = var.project_name
      run_id    = var.run_id
    }
  }
}
