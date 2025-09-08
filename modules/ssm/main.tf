# SSM Parameter Store parameters
resource "aws_ssm_parameter" "environment_config" {
  name        = "/my-namespace/config"
  description = "Environment configuration parameters"
  type        = "SecureString"
  value       = jsonencode({
    environment = var.environment
    project     = var.project_name
    region      = var.aws_region
    created_at  = timestamp()
  })
  key_id      = var.kms_key_id // Make sure to specify a valid KMS key ID
}

resource "aws_ssm_parameter" "database_connection" {
  name        = "/my-namespace/database/connection"
  description = "Database connection string"
  type        = "SecureString"
  value       = var.database_connection_string
  key_id      = var.kms_key_id

  tags = var.tags
}

resource "aws_ssm_parameter" "api_keys" {
  name        = "/my-namespace/api/keys"
  description = "API keys configuration"
  type        = "SecureString"
  value = jsonencode({
    primary_api_key   = var.primary_api_key
    secondary_api_key = var.secondary_api_key
  })
  key_id = var.kms_key_id

  tags = var.tags
}

resource "aws_ssm_parameter" "last_execution" {
  name        = "/my-namespace/automation/last-execution"
  description = "Last execution timestamp of automation"
  type        = "SecureString"
  value       = "initial"
  key_id      = var.kms_key_id // Make sure to specify a valid KMS key ID

  tags = var.tags
}

resource "aws_ssm_document" "instance_configuration" {
  name          = "my-ssm-document"
  document_type = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Configure EC2 instance for the automation project"
    parameters = {
      environment = {
        type        = "String"
        description = "Environment name"
        default     = var.environment
      },
      installCloudWatchAgent = {
        type        = "String"
        description = "Install CloudWatch agent"
        default     = "true"
        allowedValues = ["true", "false"]
      }
    }

    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "configureInstance"
        inputs = {
          timeoutSeconds = "3600"
          runCommand = [
            "#!/bin/bash",
            "set -e",
            "echo 'Starting instance configuration for environment: {{ environment }}'",
            "",
            "# Update system packages",
            "yum update -y",
            "",
            "# Install essential packages",
            "yum install -y wget curl unzip htop",
                        "",
                       "# Install CloudWatch agent if requested",
            "if [ '{{ installCloudWatchAgent }}' = 'true' ]; then",
            "  echo 'Installing CloudWatch agent'",
            "  wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",
            "  systemctl enable amazon-cloudwatch-agent",
            "fi",
            "",
            "# Configure instance tags",
            "INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)",
            "aws ec2 create-tags --resources $INSTANCE_ID --tags Key=ConfiguredBy,Value=SSM,Key=Environment,Value={{ environment }} --region ${var.aws_region}",
            "",
            "echo 'Instance configuration completed successfully'"
          ]
        }
      }
    ]
  )

  tags = var.tags
}

# SSM Association to automatically run the document on new instances
resource "aws_ssm_association" "instance_configuration" {
  name = aws_ssm_document.instance_configuration.name

  targets {
    key    = "tag:Environment"
    values = [var.environment]
  }

  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }

  schedule_expression = "rate(30 minutes)"

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_logs.bucket
    s3_key_prefix  = "ssm-logs/"
  }

  parameters = {
    environment             = var.environment
    installCloudWatchAgent = "true"
  }

  tags = var.tags
}

# KMS key for SSM parameters encryption
resource "aws_kms_key" "ssm_key" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for SSM parameters encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Enable IAM User Permissions"
        Effect   = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid      = "Allow access for Key Administrators"
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_role.key_admin.arn
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid      = "Allow use of the key"
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_role.key_user.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
  