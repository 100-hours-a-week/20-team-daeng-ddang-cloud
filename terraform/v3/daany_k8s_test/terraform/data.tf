# 최신 Ubuntu 22.04 AMI (userdata.sh가 Ubuntu 22.04 기준)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 기존 VPC 참조
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# 서브넷 정보 조회 (AZ 분산을 위해)
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}
