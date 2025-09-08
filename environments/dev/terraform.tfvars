# Configuration pour l'environnement de développement

# Informations générales
aws_region   = "us-east-1"
environment  = "dev"
project_name = "aws-automation"
owner        = "DevOps Team"

# Configuration réseau
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Configuration EC2 et Auto Scaling
instance_type     = "t3.micro"
min_size         = 1
max_size         = 3
desired_capacity = 2

# Configuration Lambda
lambda_timeout     = 300
lambda_memory_size = 128

# Configuration EventBridge
eventbridge_schedule        = "rate(5 minutes)"
use_custom_eventbridge_bus = false

# Configuration Directory Service
domain_name        = "eazytraining.local"
directory_edition  = "Standard"
directory_password = data.vault_generic_secret.directory_password.data.key # Stored in Vault

# Configuration SSM (sensible - à sécuriser)
database_connection_string = data.vault_generic_secret.database_connection_string.data.key # Stored in Vault
primary_api_key   = data.vault_generic_secret.primary_api_key.data.key # Stored in Vault
secondary_api_key = data.vault_generic_secret.secondary_api_key.data.key # Stored in Vault

# Vault provider configuration
provider "vault" {
  address = "https://your-vault-instance.com:8200"
}

# Vault data sources for sensitive values
data "vault_generic_secret" "directory_password" {
  path = "your-vault-path/directory-password"
}

data "vault_generic_secret" "database_connection_string" {
  path = "your-vault-path/database-connection-string"
}

data "vault_generic_secret" "primary_api_key" {
  path = "your-vault-path/primary-api-key"
}

data "vault_generic_secret" "secondary_api_key" {
  path = "your-vault-path/secondary-api-key"
}