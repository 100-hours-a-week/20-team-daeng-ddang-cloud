data "aws_instances" "staging" {
  filter {
    name   = "tag:env" # 태그 키이름
    values = [var.environment]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# CPU Utilization 알람
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "cpu-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeds 80%"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }

  # SNS 알림
  # alarm_actions = [aws_sns_topic.alerts.arn]
}


# Memory 알람 (CloudWatch Agent 필요)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "memory-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Memory utilization exceeds 80%"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}

# Network In 알람 (bytes)
resource "aws_cloudwatch_metric_alarm" "network_in_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "network-in-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 100000000 # 100MB
  alarm_description   = "Network In exceeds 100MB"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}

# Network Out 알람 (bytes)
resource "aws_cloudwatch_metric_alarm" "network_out_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "network-out-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 100000000 # 100MB
  alarm_description   = "Network Out exceeds 100MB"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}

# EBS Read IOPS 알람 (gp3 기준: 3,000 IOPS)
resource "aws_cloudwatch_metric_alarm" "ebs_read_iops_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "ebs-read-iops-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EBSReadOps"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  # gp3 기본 3,000 IOPS × 80% × 300초 = 720,000 ops
  threshold         = 720000
  alarm_description = "EBS Read IOPS exceeds 80% of gp3 baseline (3,000 IOPS)"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}


# EBS Write IOPS 알람 (gp3 기준: 3,000 IOPS)
resource "aws_cloudwatch_metric_alarm" "ebs_write_iops_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "ebs-write-iops-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EBSWriteOps"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  # gp3 기본 3,000 IOPS × 80% × 300초 = 720,000 ops
  threshold         = 720000
  alarm_description = "EBS Write IOPS exceeds 80% of gp3 baseline (3,000 IOPS)"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}


# EBS Read Throughput 알람 (gp3 기준: 125 MiB/s)
resource "aws_cloudwatch_metric_alarm" "ebs_read_throughput_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "ebs-read-throughput-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EBSReadBytes"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  # gp3 기본 125 MiB/s × 80% × 300초 = 30,000 MiB = 31,457,280,000 bytes
  threshold         = 31457280000
  alarm_description = "EBS Read throughput exceeds 80% of gp3 baseline (125 MiB/s)"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}


# EBS Write Throughput 알람 (gp3 기준: 125 MiB/s)
resource "aws_cloudwatch_metric_alarm" "ebs_write_throughput_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "ebs-write-throughput-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EBSWriteBytes"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  # gp3 기본 125 MiB/s × 80% × 300초 = 30,000 MiB = 31,457,280,000 bytes
  threshold         = 31457280000
  alarm_description = "EBS Write throughput exceeds 80% of gp3 baseline (125 MiB/s)"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
  }
}


# Disk Used (CloudWatch Agent 필요)
resource "aws_cloudwatch_metric_alarm" "disk_used_high" {
  count = length(data.aws_instances.staging.ids)

  alarm_name          = "disk-used-high-${data.aws_instances.staging.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Disk usage exceeds 80%"

  dimensions = {
    InstanceId = data.aws_instances.staging.ids[count.index]
    path       = "/"
    fstype     = "xfs" # 또는 ext4
  }
}


# CloudWatch 대시보드
resource "aws_cloudwatch_dashboard" "staging" {
  # count가 0이면 즉 instance가 없으면 대시보드 생성 X, 있으면 생성 O
  count          = length(data.aws_instances.staging.ids) > 0 ? 1 : 0
  dashboard_name = "staging-instances"

  dashboard_body = jsonencode({
    widgets = [
      # CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization (%)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      # Memory Utilization (CWAgent)
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Memory Utilization (%)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["CWAgent", "mem_used_percent", "InstanceId", id]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      # Network In
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Network In (Bytes)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["AWS/EC2", "NetworkIn", "InstanceId", id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      # Network Out
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Network Out (Bytes)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["AWS/EC2", "NetworkOut", "InstanceId", id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      # EBS Read Throughput (gp3: 125 MiB/s baseline)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "EBS Read Throughput (gp3: 125 MiB/s)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["AWS/EC2", "EBSReadBytes", "InstanceId", id]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      # EBS Write Throughput (gp3: 125 MiB/s baseline)
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "EBS Write Throughput (gp3: 125 MiB/s)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["AWS/EC2", "EBSWriteBytes", "InstanceId", id]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      # Disk Used (CWAgent)
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Disk Used (%)"
          region = var.region
          metrics = [
            for id in data.aws_instances.staging.ids :
            ["CWAgent", "disk_used_percent", "InstanceId", id, "path", "/", "fstype", "xfs"]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      # EBS IOPS (gp3: 3,000 IOPS baseline)
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "EBS IOPS (gp3: 3,000 IOPS)"
          region = var.region
          metrics = concat(
            [
              for id in data.aws_instances.staging.ids :
              ["AWS/EC2", "EBSReadOps", "InstanceId", id]
            ],
            [
              for id in data.aws_instances.staging.ids :
              ["AWS/EC2", "EBSWriteOps", "InstanceId", id]
            ]
          )
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}
