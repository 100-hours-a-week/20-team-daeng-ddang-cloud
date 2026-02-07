output "monitored_instance_ids" {
  description = "List of staging instance IDs being monitored"
  value       = data.aws_instances.staging.ids
}

output "monitored_instance_count" {
  description = "Number of staging instances being monitored"
  value       = length(data.aws_instances.staging.ids)
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = length(data.aws_instances.staging.ids) > 0 ? "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=staging-instances" : null
}

output "alarm_names" {
  description = "List of created CloudWatch alarm names"
  value = {
    cpu_high             = [for alarm in aws_cloudwatch_metric_alarm.cpu_high : alarm.alarm_name]
    memory_high          = [for alarm in aws_cloudwatch_metric_alarm.memory_high : alarm.alarm_name]
    network_in_high      = [for alarm in aws_cloudwatch_metric_alarm.network_in_high : alarm.alarm_name]
    network_out_high     = [for alarm in aws_cloudwatch_metric_alarm.network_out_high : alarm.alarm_name]
    ebs_read_iops_high   = [for alarm in aws_cloudwatch_metric_alarm.ebs_read_iops_high : alarm.alarm_name]
    ebs_write_iops_high  = [for alarm in aws_cloudwatch_metric_alarm.ebs_write_iops_high : alarm.alarm_name]
    ebs_read_throughput  = [for alarm in aws_cloudwatch_metric_alarm.ebs_read_throughput_high : alarm.alarm_name]
    ebs_write_throughput = [for alarm in aws_cloudwatch_metric_alarm.ebs_write_throughput_high : alarm.alarm_name]
    disk_used_high       = [for alarm in aws_cloudwatch_metric_alarm.disk_used_high : alarm.alarm_name]
  }
}