# ─── K8s API Server용 NLB ─────────────────────────────────────

resource "aws_lb" "k8s_api" {
  name               = "danny-k8s-api-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.nlb.id]

  tags = {
    Name = "danny-k8s-api-nlb"
  }
}

# ─── Target Group: API Server (6443) ─────────────────────────

resource "aws_lb_target_group" "k8s_api" {
  name     = "danny-k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = 6443
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = {
    Name = "danny-k8s-api-tg"
  }
}

# ─── Master 노드를 Target Group에 등록 ───────────────────────

resource "aws_lb_target_group_attachment" "k8s_api" {
  count            = var.master_count
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443
}

# ─── Listener: 6443 → Master Target Group ────────────────────

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}
