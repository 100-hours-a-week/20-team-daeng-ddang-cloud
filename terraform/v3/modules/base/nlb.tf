resource "aws_lb" "kube_apiserver_internal" {
  name               = substr(replace("${local.name_prefix}-api-int-nlb", "_", "-"), 0, 32)
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
  security_groups    = [aws_security_group.internal_nlb_sg.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-int-nlb"
  })
}

resource "aws_lb_target_group" "kube_apiserver_tg" {
  name        = substr(replace("${local.name_prefix}-api-tg", "_", "-"), 0, 32)
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "6443"
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "kube_apiserver_6443" {
  load_balancer_arn = aws_lb.kube_apiserver_internal.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_apiserver_tg.arn
  }
}