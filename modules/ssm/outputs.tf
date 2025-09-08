output "ssm_document_name" {
  description = "Name of the SSM document"
  value       = aws_ssm_document.instance_configuration.name
}

output "ssm_document_arn" {
  description = "ARN of the SSM document"
  value       = aws_ssm_document.instance_configuration.arn
}

output "parameter_names" {
  description = "List of SSM parameter names"
  value = [
    aws_ssm_parameter.environment_config.name,
    aws_ssm_parameter.database_connection.name,
    aws_ssm_parameter.api_keys.name,
    aws_ssm_parameter.last_execution.name
  ]
}

output "kms_key_id" {
  description = "KMS key ID for SSM parameters"
  value       = aws_ssm_parameter.kms_key_id.value
}

output "kms_key_arn" {
  description = "KMS key ARN for SSM parameters"
  value       = aws_kms_key.ssm_key[0].arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for SSM logs"
  value       = aws_s3_bucket.ssm_logs.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for SSM logs"
  value       = aws_s3_bucket.ssm_logs.arn
}

output "environment_config" {
  description = "Environment configuration"
  value       = aws_ssm_parameter.environment_config.value
}

output "database_connection" {
  description = "Database connection string"
  value       = aws_ssm_parameter.database_connection.value
}

output "api_keys" {
  description = "API keys configuration"
  value       = aws_ssm_parameter.api_keys.value
}

output "last_execution" {
  description = "Last execution timestamp of automation"
  value       = aws_ssm_parameter.last_execution.value
}