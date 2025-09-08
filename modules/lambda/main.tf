# Archive Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-automation"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Lambda function
resource "aws_lambda_function" "automation_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-automation"
  role             = var.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      ENVIRONMENT   = var.environment
      PROJECT_NAME  = var.project_name
      LOG_LEVEL     = var.log_level
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
  tags       = var.tags
}

# Lambda permissions for EventBridge
resource "aws_lambda_permission" "allow_scheduled_event" {
  statement_id  = "AllowScheduledEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.automation_lambda.function_name
  principal     = "events.amazonaws.com"
  #source_arn    = var.scheduled_rule_arn
}

resource "aws_lambda_permission" "allow_ec2_event" {
  statement_id  = "AllowEC2Event"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.automation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.ec2_rule_arn
}

resource "aws_lambda_permission" "allow_autoscaling_event" {
  statement_id  = "AllowAutoScalingEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.automation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.autoscaling_rule_arn
}
