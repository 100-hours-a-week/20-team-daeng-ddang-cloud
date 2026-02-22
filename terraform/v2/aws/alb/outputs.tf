output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "be_target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "fe_target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "fe_target_group_2_arn" {
  value = aws_lb_target_group.frontend_2.arn
}