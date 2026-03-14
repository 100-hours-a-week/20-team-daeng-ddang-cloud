resource "aws_iam_role" "control_plane_role" {
  name = "${local.name_prefix}-control-plane-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "worker_role" {
  name = "${local.name_prefix}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "${local.name_prefix}-control-plane-profile"
  role = aws_iam_role.control_plane_role.name
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "${local.name_prefix}-worker-profile"
  role = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.control_plane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "worker_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
