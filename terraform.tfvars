# Exemple de configuration - Copiez ce fichier vers terraform.tfvars et personnalisez

# OBLIGATOIRE: Informations générales
aws_region   = "us-east-1"
environment  = "dev"
project_name = "aws-automation" 
owner        = "EAZYTraining"

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

# SENSIBLE: À définir de manière sécurisée
directory_password            = "EazyDirectory123@"
database_connection_string = "postgresql://placeholder:5432/eazy-automation-db"
primary_api_key   = "eazy-primary-2024-a8f3k9m2x7q1"
secondary_api_key = "eazy-secondary-2024-b5n8r4p9w2z6"