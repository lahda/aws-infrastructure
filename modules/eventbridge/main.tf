# EventBridge custom bus (optional - can use default)
resource "aws_cloudwatch_event_bus" "custom_bus" {
  count = var.use_custom_bus ? 1 : 0
  name  = "${var.project_name}-${var.environment}-bus"

  tags = var.tags
}

# Scheduled rule for periodic automation
resource "aws_cloudwatch_event_rule" "scheduled_rule" {
  name                = "${var.project_name}-${var.environment}-scheduled"
  description         = "Scheduled rule for automation tasks"
  schedule_expression = var.schedule_expression
  event_bus_name      = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"

  tags = var.tags
}

# EC2 state change rule
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name           = "${var.project_name}-${var.environment}-ec2-state-change"
  description    = "Capture EC2 state changes"
  event_bus_name = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "stopped", "terminated"]
    }
  })

  tags = var.tags
}

# Auto Scaling event rule
resource "aws_cloudwatch_event_rule" "autoscaling_events" {
  name           = "${var.project_name}-${var.environment}-autoscaling"
  description    = "Capture Auto Scaling events"
  event_bus_name = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = [
      "EC2 Instance Launch Successful",
      "EC2 Instance Launch Unsuccessful",
      "EC2 Instance Terminate Successful",
      "EC2 Instance Terminate Unsuccessful"
    ]
  })

  tags = var.tags
}

# EventBridge target for scheduled rule
resource "aws_cloudwatch_event_target" "scheduled_lambda_target" {
  rule           = aws_cloudwatch_event_rule.scheduled_rule.name
  target_id      = "ScheduledLambdaTarget"
  arn            = var.lambda_function_arn
  event_bus_name = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"

  input = jsonencode({
    source        = "eventbridge.scheduled"
    detail-type   = "Scheduled Event"
    detail = {
      trigger = "scheduled_automation"
    }
  })
}

# EventBridge target for EC2 state changes
resource "aws_cloudwatch_event_target" "ec2_lambda_target" {
  rule           = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id      = "EC2LambdaTarget"
  arn            = var.lambda_function_arn
  event_bus_name = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"
}

# EventBridge target for Auto Scaling events
resource "aws_cloudwatch_event_target" "autoscaling_lambda_target" {
  rule           = aws_cloudwatch_event_rule.autoscaling_events.name
  target_id      = "AutoScalingLambdaTarget"
  arn            = var.lambda_function_arn
  event_bus_name = var.use_custom_bus ? aws_cloudwatch_event_bus.custom_bus[0].name : "default"
}

# CloudWatch Log Group for EventBridge
resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = "/aws/events/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}