variable "project_name" { type = string }
variable "environment" { type = string }

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "s3_cors_allowed_origins" { type = list(string) }
variable "s3_cors_allowed_methods" {
  type    = list(string)
  default = ["GET", "HEAD", "PUT", "POST", "DELETE"]
}
variable "s3_cors_allowed_headers" {
  type    = list(string)
  default = ["*"]
}
variable "s3_cors_expose_headers" {
  type    = list(string)
  default = ["ETag"]
}
variable "s3_cors_max_age_seconds" {
  type    = number
  default = 3000
}
