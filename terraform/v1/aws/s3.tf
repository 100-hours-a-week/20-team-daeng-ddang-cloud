resource "aws_s3_bucket" "daeng_map" {
  bucket = var.project_name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3"
  })
}

resource "aws_s3_bucket_public_access_block" "daeng_map" {
  bucket = aws_s3_bucket.daeng_map.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "daeng_map" {
  bucket = aws_s3_bucket.daeng_map.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "daeng_map_public_read" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.daeng_map.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "daeng_map" {
  bucket = aws_s3_bucket.daeng_map.id
  policy = data.aws_iam_policy_document.daeng_map_public_read.json

  # PublicAccessBlock 선적용 후 정책 적용 (적용 순서 안정화용)
  depends_on = [aws_s3_bucket_public_access_block.daeng_map]
}

resource "aws_s3_bucket_cors_configuration" "daeng_map" {
  bucket = aws_s3_bucket.daeng_map.id

  cors_rule {
    allowed_origins = var.s3_cors_allowed_origins
    allowed_methods = var.s3_cors_allowed_methods
    allowed_headers = var.s3_cors_allowed_headers
    expose_headers  = var.s3_cors_expose_headers
    max_age_seconds = var.s3_cors_max_age_seconds
  }

  # 버킷 생성 이후 적용되도록 보장
  depends_on = [aws_s3_bucket.daeng_map]
}