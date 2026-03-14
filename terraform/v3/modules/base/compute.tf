# Create EC2 for Control Planes & Worker Nodes

resource "aws_instance" "control_plane" {
  count                  = var.control_plane_instance_count
  ami                    = var.ami_id
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
    ${templatefile("${path.module}/userdata-common.sh.tpl", {
  node_name = local.control_plane_names[count.index]
})}
    ${templatefile("${path.module}/userdata-control-plane.sh.tpl", {})}
  EOF

tags = merge(local.common_tags, {
  Name = local.control_plane_names[count.index]
  Role = "control-plane"
})
}

resource "aws_instance" "worker" {
  count                  = var.worker_instance_count
  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = concat([aws_security_group.worker_sg.id], var.node_additional_security_group_ids)
  iam_instance_profile   = aws_iam_instance_profile.worker_profile.name
  key_name               = var.key_name

  associate_public_ip_address = false

  root_block_device {
    volume_size           = var.worker_root_volume_size
    volume_type           = var.worker_root_volume_type
    delete_on_termination = true
  }

  user_data = <<-EOF
    ${templatefile("${path.module}/userdata-common.sh.tpl", {
  node_name = local.worker_names[count.index]
})}
    ${templatefile("${path.module}/userdata-worker.sh.tpl", {})}
  EOF

tags = merge(local.common_tags, {
  Name = local.worker_names[count.index]
  Role = "worker"
})
}

resource "aws_lb_target_group_attachment" "control_plane_to_api_tg" {
  count            = var.control_plane_instance_count
  target_group_arn = aws_lb_target_group.kube_apiserver_tg.arn
  target_id        = aws_instance.control_plane[count.index].id
  port             = 6443
}