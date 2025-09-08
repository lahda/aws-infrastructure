variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-automation"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "directory_password" {
  description = "Password for AWS Directory Service"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for Directory Service"
  type        = string
  default     = "corp.example.com"
}

variable "directory_edition" {
  description = "Edition of AWS Directory Service"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Enterprise", "Standard"], var.directory_edition)
    error_message = "Directory edition must be either 'Enterprise' or 'Standard'."
  }
}

variable "eventbridge_schedule" {
  description = "EventBridge schedule expression"
  type        = string
  default     = "rate(5 minutes)"
}

variable "use_custom_eventbridge_bus" {
  description = "Use custom EventBridge bus"
  type        = bool
  default     = false
}

variable "database_connection_string" {
  description = "Database connection string"
  type        = string
  sensitive   = true
  default     = "postgresql://localhost:5432/defaultdb"
}

variable "primary_api_key" {
  description = "Primary API key"
  type        = string
  sensitive   = true
  default     = vault("secret/data/api_keys", "primary_api_key")
}

variable "secondary_api_key" {
  description = "Secondary API key"
  type        = string
  sensitive   = true
  default     = vault("secret/data/api_keys", "secondary_api_key")
}

