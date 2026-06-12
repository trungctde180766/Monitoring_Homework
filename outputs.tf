output "instance_id" {
  value       = aws_instance.monitored_instance.id
  description = "The ID of the EC2 instance being monitored"
}

output "instance_public_ip" {
  value       = aws_instance.monitored_instance.public_ip
  description = "The public IP of the EC2 instance (for SSH access if needed)"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.cpu_alarm_topic.arn
  description = "The ARN of the SNS Topic created"
}

output "cloudwatch_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.cpu_high_alarm.alarm_name
  description = "The name of the CloudWatch CPU Alarm"
}

output "cloudwatch_memory_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.memory_high_alarm.alarm_name
  description = "The name of the CloudWatch Memory Alarm"
}

output "subscription_instructions" {
  value       = "IMPORTANT: AWS SNS has sent a subscription confirmation email to the email address you configured. You MUST open your inbox and click the 'Confirm Subscription' link to begin receiving alerts."
  description = "Instructions for finalizing the email subscription"
}
