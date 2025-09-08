output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 SSM role"
  value       = aws_iam_role.ec2_ssm_role.arn
}

output "eventbridge_role_arn" {
  description = "ARN of the EventBridge role"
  value       = aws_iam_role.eventbridge_role.arn
}