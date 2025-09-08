variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the directory service"
  type        = string
  default     = "corp.example.com"
}

variable "admin_password" {
  description = "Administrator password for the directory"
  type        = string
  sensitive   = true
}

variable "edition" {
  description = "Edition of AWS Managed Microsoft AD"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Enterprise", "Standard"], var.edition)
    error_message = "Edition must be either 'Enterprise' or 'Standard'."
  }
}

variable "vpc_id" {
  description = "VPC ID where the directory will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the directory (must be in different AZs)"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "enable_log_subscription" {
  description = "Enable log subscription for directory service"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "create_dhcp_options" {
  description = "Create DHCP options set for the directory"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}