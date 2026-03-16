locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  control_plane_names = [
    for i in range(var.control_plane_instance_count) :
    "${local.name_prefix}-cp-${i + 1}"
  ]

  worker_join_ssm_parameter_name        = "/${var.project_name}/${var.environment}/k8s/worker_join_command"
  control_plane_join_ssm_parameter_name = "/${var.project_name}/${var.environment}/k8s/control_plane_join_command"
}