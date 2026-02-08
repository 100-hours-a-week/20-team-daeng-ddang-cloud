data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name != "" ? var.key_name : null

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.block_device_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-server"
  }
}

resource "aws_eip" "server" {
  count  = var.use_eip ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-server-eip"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip_association" "server" {
  count         = var.use_eip ? 1 : 0
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.server[0].allocation_id
}
