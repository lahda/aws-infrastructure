variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "database_connection_string" {
  description = "Database connection string"
  type        = string
  sensitive   = true
}

variable "primary_api_key" {
  description = "Primary API key"
  type        = string
  sensitive   = true
}

variable "secondary_api_key" {
  description = "Secondary API key"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for parameter encryption"
  type        = string
}

variable "create_kms_key" {
  description = "Whether to create a new KMS key"
  type        = bool
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
}