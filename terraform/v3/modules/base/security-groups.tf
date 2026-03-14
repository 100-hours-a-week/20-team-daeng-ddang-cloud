resource "aws_security_group" "internal_nlb_sg" {
  name        = "${local.name_prefix}-internal-nlb-sg"
  description = "Security group for internal Kubernetes API NLB"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-internal-nlb-sg"
  })
}

resource "aws_security_group" "control_plane_sg" {
  name        = "${local.name_prefix}-cp-sg"
  description = "Security group for control plane nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cp-sg"
  })
}

resource "aws_security_group" "worker_sg" {
  name        = "${local.name_prefix}-worker-sg"
  description = "Security group for worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-worker-sg"
  })
}

# === internal NLB SG ====

resource "aws_security_group_rule" "internal_nlb_ingress_6443_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.internal_nlb_sg.id
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Allow kube-apiserver access from control planes"
}

resource "aws_security_group_rule" "internal_nlb_ingress_6443_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.internal_nlb_sg.id
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "Allow kube-apiserver access from workers"
}

resource "aws_security_group_rule" "internal_nlb_egress_6443_to_cp" {
  type                     = "egress"
  security_group_id        = aws_security_group.internal_nlb_sg.id
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Forward API traffic to control planes"
}

# === Control Plane SG ====

resource "aws_security_group_rule" "cp_ingress_6443_from_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.control_plane_sg.id
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Kubernetes API from VPC"
}

resource "aws_security_group_rule" "cp_ingress_2379_2380_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "etcd peer and client traffic between control planes"
}

resource "aws_security_group_rule" "cp_ingress_10257_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 10257
  to_port                  = 10257
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "kube-controller-manager"
}

resource "aws_security_group_rule" "cp_ingress_10259_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 10259
  to_port                  = 10259
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "kube-scheduler"
}

resource "aws_security_group_rule" "cp_ingress_10250_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "kubelet API from control planes"
}

resource "aws_security_group_rule" "cp_ingress_10250_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "kubelet API from workers if needed"
}

resource "aws_security_group_rule" "cp_ingress_calico_bgp_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Calico BGP from control planes"
}

resource "aws_security_group_rule" "cp_ingress_calico_bgp_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "Calico BGP from workers"
}

resource "aws_security_group_rule" "cp_ingress_ipip_from_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.control_plane_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "4"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Calico IP-in-IP traffic from VPC"
}

resource "aws_security_group_rule" "cp_ingress_nodeport_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "NodePort from control planes"
}

resource "aws_security_group_rule" "cp_ingress_nodeport_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.control_plane_sg.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "NodePort from workers"
}

resource "aws_security_group_rule" "cp_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.control_plane_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound from control plane"
}

# === Worker SG ====

resource "aws_security_group_rule" "worker_ingress_10250_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "kubelet API from control planes"
}

resource "aws_security_group_rule" "worker_ingress_10250_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "kubelet API between workers if needed"
}

resource "aws_security_group_rule" "worker_ingress_calico_bgp_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Calico BGP from control planes"
}

resource "aws_security_group_rule" "worker_ingress_calico_bgp_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "Calico BGP from workers"
}

resource "aws_security_group_rule" "worker_ingress_ipip_from_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.worker_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "4"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Calico IP-in-IP traffic from VPC"
}

resource "aws_security_group_rule" "worker_ingress_nodeport_from_cp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "NodePort from control planes"
}

resource "aws_security_group_rule" "worker_ingress_nodeport_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "NodePort from workers"
}

resource "aws_security_group_rule" "worker_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.worker_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound from worker"
}