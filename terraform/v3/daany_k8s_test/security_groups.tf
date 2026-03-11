# ─── Master 노드 보안 그룹 (콘솔에서 생성 → import) ──────────

resource "aws_security_group" "k8s_master" {
  name        = "danny-k8s-master-node-sg"
  description = "danny-k8s-master-node-sg"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API Server (master self)
  ingress {
    description = "API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  # API Server (NLB 경유 - 헬스체크 + 외부 접근)
  ingress {
    description     = "API Server via NLB"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  # etcd (master self)
  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  # Kubelet API (master self)
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  # kube-scheduler (master self)
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    self        = true
  }

  # BGP - Calico (master self)
  ingress {
    description = "BGP"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    self        = true
  }

  # CoreDNS TCP (master self)
  ingress {
    description = "Core DNS - TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    self        = true
  }

  # CoreDNS UDP (master self)
  ingress {
    description = "Core DNS - UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  # IP-in-IP - Calico (master self)
  ingress {
    description = "IP-in-IP"
    from_port   = 0
    to_port     = 0
    protocol    = "4"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "danny-k8s-master-node-sg"
    k8s-role = "master"
  }
}

# ─── Worker 노드 보안 그룹 (콘솔에서 생성 → import) ──────────

resource "aws_security_group" "k8s_worker" {
  name        = "danny-k8s-worker-node-sg"
  description = "danny-k8s-worker-node-sg"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort
  ingress {
    description = "NodePort"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BGP (worker self)
  ingress {
    description = "179"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    self        = true
  }

  # CoreDNS TCP (worker self)
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "tcp"
    self      = true
  }

  # CoreDNS UDP (worker self)
  ingress {
    description = "Core DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  # IP-in-IP - Calico (worker self)
  ingress {
    description = "IP-in-IP"
    from_port   = 0
    to_port     = 0
    protocol    = "4"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "danny-k8s-worker-node-sg"
  }
}

# ─── NLB 보안 그룹 ────────────────────────────────────────────

resource "aws_security_group" "nlb" {
  name        = "danny-k8s-nlb-sg"
  description = "danny-k8s-nlb-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "K8s API from anywhere"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "danny-k8s-nlb-sg"
  }
}

# ─── 교차 참조 규칙 (worker → master, master → worker) ───────
# SG 간 순환 참조를 피하기 위해 별도 rule로 분리

# Worker → Master: API Server
resource "aws_security_group_rule" "master_from_worker_api" {
  type                     = "ingress"
  description              = "API Server"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Worker → Master: Kubelet API
resource "aws_security_group_rule" "master_from_worker_kubelet" {
  type                     = "ingress"
  description              = "Kubelet API"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Worker → Master: BGP (Calico)
resource "aws_security_group_rule" "master_from_worker_bgp" {
  type                     = "ingress"
  description              = "BGP"
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Worker → Master: CoreDNS TCP
resource "aws_security_group_rule" "master_from_worker_dns_tcp" {
  type                     = "ingress"
  description              = "Core DNS - TCP"
  from_port                = 53
  to_port                  = 53
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Worker → Master: CoreDNS UDP (콘솔에서 TCP/port 0으로 설정된 항목 그대로 반영)
resource "aws_security_group_rule" "master_from_worker_dns_udp" {
  type                     = "ingress"
  description              = "Core DNS - UDP"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Worker → Master: IP-in-IP (Calico)
resource "aws_security_group_rule" "master_from_worker_ipip" {
  type                     = "ingress"
  description              = "IP-in-IP"
  from_port                = 0
  to_port                  = 0
  protocol                 = "4"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_worker.id
}

# Master → Worker: Kubelet API
resource "aws_security_group_rule" "worker_from_master_kubelet" {
  type                     = "ingress"
  description              = "Kubelet API"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_worker.id
  source_security_group_id = aws_security_group.k8s_master.id
}

# Master → Worker: BGP (Calico)
resource "aws_security_group_rule" "worker_from_master_bgp" {
  type                     = "ingress"
  description              = "BGP"
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_worker.id
  source_security_group_id = aws_security_group.k8s_master.id
}

# Master → Worker: CoreDNS TCP
resource "aws_security_group_rule" "worker_from_master_dns_tcp" {
  type                     = "ingress"
  description              = "Core DNS-TCP"
  from_port                = 53
  to_port                  = 53
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_worker.id
  source_security_group_id = aws_security_group.k8s_master.id
}

# Master → Worker: CoreDNS UDP
resource "aws_security_group_rule" "worker_from_master_dns_udp" {
  type                     = "ingress"
  description              = "Core DNS-UDP"
  from_port                = 53
  to_port                  = 53
  protocol                 = "udp"
  security_group_id        = aws_security_group.k8s_worker.id
  source_security_group_id = aws_security_group.k8s_master.id
}

# Master → Worker: IP-in-IP (Calico)
resource "aws_security_group_rule" "worker_from_master_ipip" {
  type                     = "ingress"
  description              = "IP-in-IP"
  from_port                = 0
  to_port                  = 0
  protocol                 = "4"
  security_group_id        = aws_security_group.k8s_worker.id
  source_security_group_id = aws_security_group.k8s_master.id
}
