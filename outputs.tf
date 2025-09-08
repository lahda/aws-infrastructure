# VPC and Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.ec2.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.ec2.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.ec2.private_subnet_ids
}

# Auto Scaling Group Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_arn
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

# IAM Outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_name
}

# SSM Outputs
output "ssm_document_name" {
  description = "Name of the SSM document"
  value       = module.ssm.ssm_document_name
}

output "ssm_parameter_names" {
  description = "List of SSM parameter names"
  value       = module.ssm.parameter_names
}

output "ssm_s3_bucket" {
  description = "S3 bucket for SSM logs"
  value       = module.ssm.s3_bucket_name
}

# Directory Service Outputs
output "directory_id" {
  description = "ID of the Directory Service"
  value       = module.directory.directory_id
}

output "directory_dns_ips" {
  description = "DNS IP addresses of the directory"
  value       = module.directory.dns_ip_addresses
}

output "directory_access_url" {
  description = "Access URL for the directory"
  value       = module.directory.access_url
}

# EventBridge Outputs
output "eventbridge_scheduled_rule_arn" {
  description = "ARN of the scheduled EventBridge rule"
  value       = module.eventbridge.scheduled_rule_arn
}


output "eventbridge_ec2_rule_arn" {
  description = "ARN of the EC2 state change EventBridge rule"
  value       = module.eventbridge.ec2_rule_arn
}

output "eventbridge_autoscaling_rule_arn" {
  description = "ARN of the Auto Scaling EventBridge rule"
  value       = module.eventbridge.autoscaling_rule_arn
}

# General Information
output "project_info" {
  description = "Project information"
  value = {
    name        = var.project_name
    environment = var.environment
    region      = var.aws_region
    owner       = var.owner
  }
}