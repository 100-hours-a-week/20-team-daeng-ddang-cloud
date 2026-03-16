# ─── Master Nodes ─────────────────────────────────────────────

resource "aws_instance" "master" {
  count = var.master_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.master_instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.k8s_master.id,
  ]

  root_block_device {
    volume_size           = var.block_device_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/script/userdata.sh")

  tags = {
    Name = "danny-k8s-master-${count.index + 1}"
    Role = "master"
  }
}

# ─── Worker Nodes ─────────────────────────────────────────────

resource "aws_instance" "worker" {
  count = var.worker_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.k8s_worker.id,
  ]

  root_block_device {
    volume_size           = var.block_device_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/script/userdata.sh")

  tags = {
    Name = "danny-k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
