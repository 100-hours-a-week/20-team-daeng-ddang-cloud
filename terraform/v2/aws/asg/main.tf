##############################
# Security Group
##############################
resource "aws_security_group" "asg" {
  name        = "${var.project_name}-${var.environment}-asg-sg"
  description = "ASG Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  dynamic "ingress" {
    for_each = var.additional_app_ports
    content {
      description     = "App from ALB (port ${ingress.value})"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [var.alb_sg_id]
    }
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  ingress {
    description = "Node Exporter for Prometheus"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.monitoring_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-asg-sg"
  }
}

##############################
# IAM Role (SSM)
##############################
resource "aws_iam_role" "asg" {
  name = "${var.project_name}-${var.environment}-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-asg-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "asg" {
  name = "${var.project_name}-${var.environment}-asg-profile"
  role = aws_iam_role.asg.name
}

##############################
# Launch Template
##############################
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  user_data     = var.user_data

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.asg.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.block_device_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-${var.environment}-server"
    }
  }
}

##############################
# Auto Scaling Group
##############################
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.target_group_arns

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  // CI-CD 만들고 난 후 ELB로 변경하기
  //health_check_type         = "ELB"
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-server"
    propagate_at_launch = true
  }
}

##############################
# Scaling Policy (CPU Target Tracking)
##############################
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}