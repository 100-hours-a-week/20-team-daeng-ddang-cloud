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

  worker_names = [
    for i in range(var.worker_instance_count) :
    "${local.name_prefix}-worker-${i + 1}"
  ]
}