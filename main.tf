# Local values for common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# SSM Module
module "ssm" {
  source = "./modules/ssm"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  database_connection_string  = var.database_connection_string
  primary_api_key            = var.primary_api_key
  secondary_api_key          = var.secondary_api_key
  create_kms_key             = true
  tags                       = local.common_tags

  depends_on = [module.iam]
}

# EC2 and VPC Module
module "ec2" {
  source = "./modules/ec2"

  project_name               = var.project_name
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  ssm_document_name         = module.ssm.ssm_document_name
  tags                      = local.common_tags

  depends_on = [module.iam, module.ssm]
}

# Directory Service Module
module "directory" {
  source = "./modules/directory"

  project_name      = var.project_name
  environment       = var.environment
  domain_name       = var.domain_name
  admin_password    = var.directory_password
  edition          = var.directory_edition
  vpc_id           = module.ec2.vpc_id
  subnet_ids       = module.ec2.private_subnet_ids
  vpc_cidr         = var.vpc_cidr
  tags             = local.common_tags

  depends_on = [module.ec2]
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"

  project_name         = var.project_name
  environment         = var.environment
  lambda_role_arn     = module.iam.lambda_role_arn
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size
  log_retention_days  = 14
  log_level          = "INFO"
  tags               = local.common_tags
  eventbridge_rule_arn = module.eventbridge.scheduled_rule_arn
  ec2_rule_arn       = module.eventbridge.ec2_rule_arn
  autoscaling_rule_arn = module.eventbridge.autoscaling_rule_arn
}
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name        = var.project_name
  environment        = var.environment
  lambda_function_arn = module.lambda.lambda_function_arn
  schedule_expression = var.eventbridge_schedule
  use_custom_bus     = var.use_custom_eventbridge_bus
}



# Additional Lambda permission for EventBridge (fixing circular dependency)
resource "aws_lambda_permission" "eventbridge_scheduled" {
  statement_id  = "AllowEventBridgeScheduled"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.scheduled_rule_arn

  depends_on = [module.lambda, module.eventbridge]
}

resource "aws_lambda_permission" "eventbridge_ec2" {
  statement_id  = "AllowEventBridgeEC2"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.ec2_rule_arn

  depends_on = [module.lambda, module.eventbridge]
}

resource "aws_lambda_permission" "eventbridge_autoscaling" {
  statement_id  = "AllowEventBridgeAutoScaling"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.autoscaling_rule_arn

  depends_on = [module.lambda, module.eventbridge]
}