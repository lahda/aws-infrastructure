# AWS Managed Microsoft AD
resource "aws_directory_service_directory" "main" {
  name       = var.domain_name
  password   = var.admin_password
  edition    = var.edition
  type       = "MicrosoftAD"
  
  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  description = "AWS Managed Microsoft AD for ${var.project_name} ${var.environment}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-directory"
  })
}

# Directory Service Log Group
resource "aws_cloudwatch_log_group" "directory_logs" {
  name              = "/aws/directoryservice/${aws_directory_service_directory.main.id}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Directory Service Log Subscription (optional)
resource "aws_directory_service_log_subscription" "main" {
  count = var.enable_log_subscription ? 1 : 0
  
  directory_id   = aws_directory_service_directory.main.id
  log_group_name = aws_cloudwatch_log_group.directory_logs.name
}

# DHCP Options Set for the directory
resource "aws_vpc_dhcp_options" "main" {
  count = var.create_dhcp_options ? 1 : 0

  domain_name_servers = aws_directory_service_directory.main.dns_ip_addresses
  domain_name         = var.domain_name
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-dhcp-options"
  })
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.create_dhcp_options ? 1 : 0
  
  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}

# Security Group for Directory Service
resource "aws_security_group" "directory" {
  name_prefix = "${var.project_name}-${var.environment}-directory-"
  description = "Security group for AWS Directory Service"
  vpc_id      = var.vpc_id

  # LDAP
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # LDAPS
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kerberos
  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RPC
  ingress {
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Dynamic RPC
  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-directory-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}