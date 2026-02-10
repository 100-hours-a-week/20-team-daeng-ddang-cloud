terraform {
  required_version = ">= 1.0.0"

  backend "s3" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.38.0"
    }
  }
}