# =========================
# Control Plane EC2
# =========================

resource "aws_instance" "control_plane" {
  count                  = var.control_plane_instance_count
  ami                    = var.control_plane_ami_id
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = concat([aws_security_group.control_plane_sg.id], var.node_additional_security_group_ids)
  iam_instance_profile   = aws_iam_instance_profile.control_plane_profile.name
  key_name               = var.key_name

  associate_public_ip_address = false

  root_block_device {
    volume_size           = var.control_plane_root_volume_size
    volume_type           = var.control_plane_root_volume_type
    delete_on_termination = true
  }

  user_data = <<-EOF
    ${templatefile("${path.module}/userdata-common.sh.tpl", {})}
    ${templatefile("${path.module}/userdata-control-plane.sh.tpl", {
    node_name = local.control_plane_names[count.index]
  })}
  EOF

lifecycle {
  ignore_changes = [user_data]
}

  tags = merge(local.common_tags, {
    Name                                = local.control_plane_names[count.index]
    Role                                = "control-plane"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
  })
}

resource "aws_lb_target_group_attachment" "control_plane_to_api_tg" {
  count            = var.control_plane_instance_count
  target_group_arn = aws_lb_target_group.kube_apiserver_tg.arn
  target_id        = aws_instance.control_plane[count.index].id
  port             = 6443
}

# =========================
# Worker Launch Template
# =========================

resource "aws_launch_template" "worker" {
  name_prefix   = "${local.name_prefix}-worker-"
  image_id      = var.worker_ami_id
  instance_type = var.worker_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }

  vpc_security_group_ids = concat(
    [aws_security_group.worker_sg.id],
    var.node_additional_security_group_ids
  )

  update_default_version = true

  user_data = base64encode(<<-EOF
    ${templatefile("${path.module}/userdata-worker.sh.tpl", {
      aws_region                   = var.aws_region
      worker_join_ssm_parameter_name = local.worker_join_ssm_parameter_name
    })}
  EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.worker_root_volume_size
      volume_type           = var.worker_root_volume_type
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-worker"
      Role = "worker"
      "kubernetes.io/cluster/${local.name_prefix}" = "owned"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-worker-volume"
      Role = "worker"
    })
  }
}

# =========================
# Worker ASG
# =========================

resource "aws_autoscaling_group" "worker" {
  name                = "${local.name_prefix}-worker-asg"
  desired_capacity    = var.worker_asg_desired_capacity
  min_size            = var.worker_asg_min_size
  max_size            = var.worker_asg_max_size
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.name_prefix}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
