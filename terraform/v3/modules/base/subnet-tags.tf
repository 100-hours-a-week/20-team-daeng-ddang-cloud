# 기존에 있는 Subnet에 태그 추가

resource "aws_ec2_tag" "public_subnet_role_elb" {
  for_each    = var.envoy_public_nlb_enabled ? toset(var.public_subnet_ids) : toset([])
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster_shared" {
  for_each    = var.envoy_public_nlb_enabled ? toset(var.public_subnet_ids) : toset([])
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.name_prefix}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_role_internal_elb" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_shared" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.name_prefix}"
  value       = "shared"
}