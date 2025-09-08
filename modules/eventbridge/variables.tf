variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression for the scheduled rule"
  type        = string
  default     = "rate(5 minutes)"
}

variable "use_custom_bus" {
  description = "Use a custom EventBridge bus instead of default"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}