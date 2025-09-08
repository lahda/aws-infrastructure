variable "project_name" {
  type        = string
  description = "Nom du projet"
}

variable "environment" {
  type        = string
  description = "Nom de l'environnement"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN du rôle IAM pour Lambda"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Durée de rétention des logs CloudWatch"
}

variable "timeout" {
  type        = number
  default     = 60
  description = "Timeout de la Lambda en secondes"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Mémoire allouée à la Lambda (MB)"
}

variable "log_level" {
  type        = string
  default     = "INFO"
}

# ARNs EventBridge
variable "eventbridge_rule_arn" {
  type        = string
  description = "ARN of the EventBridge rule"
}
variable "ec2_rule_arn" {
  type        = string
  description = "ARN de la règle EventBridge sur changement d'état EC2"
}

variable "autoscaling_rule_arn" {
  type        = string
  description = "ARN de la règle EventBridge sur Auto Scaling"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags à appliquer sur les ressources"
}
