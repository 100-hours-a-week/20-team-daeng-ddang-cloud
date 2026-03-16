aws_region  = ""
environment = ""
profile     = ""

vpc_id   = ""
vpc_cidr = ""

private_subnet_ids = []

public_subnet_ids = []

control_plane_ami_id = ""
worker_ami_id        = ""
key_name             = ""

control_plane_instance_type = ""
worker_instance_type        = ""

# 처음 apply 시엔 0 & 수동 작업 이후 원하는 값으로 설정하고 재 apply (README 참고)
worker_asg_desired_capacity = 0
worker_asg_min_size         = 0

worker_asg_max_size = 9
