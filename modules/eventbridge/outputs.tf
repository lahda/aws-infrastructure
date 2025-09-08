output "event_bus_name" {
  description = "Name of the EventBridge bus"
  value       = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"
}

output "event_bus_arn" {
  description = "ARN of the EventBridge bus"
  value       = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].arn : null
}

output "scheduled_rule_arn" {
  description = "ARN of the scheduled EventBridge rule"
  value       = aws_cloudwatch_event_rule.scheduled_rule.arn
}

output "ec2_rule_arn" {
  description = "ARN of the EC2 state change EventBridge rule"
  value       = aws_cloudwatch_event_rule.ec2_state_change.arn
}

output "autoscaling_rule_arn" {
  description = "ARN of the Auto Scaling EventBridge rule"
  value       = aws_cloudwatch_event_rule.autoscaling_events.arn
}