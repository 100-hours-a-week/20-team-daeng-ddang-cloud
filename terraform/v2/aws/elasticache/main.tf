##############################
# Subnet Group
##############################
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  }
}

##############################
# Security Group
##############################
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "ElastiCache Redis Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from allowed SGs"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  }
}

##############################
# Redis Replication Group
##############################
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "${var.project_name} ${var.environment} Redis"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters              = var.num_cache_clusters
  parameter_group_name            = var.parameter_group_name
  port                            = var.redis_port
  preferred_cache_cluster_azs     = var.preferred_cache_cluster_azs

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = var.num_cache_clusters > 1 ? true : false

  lifecycle {
    ignore_changes = [auth_token_update_strategy]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }
}