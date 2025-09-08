#!/bin/bash

# User Data Script for EC2 instances
# This script runs on instance launch

set -e

# Variables from template
ENVIRONMENT="${environment}"
PROJECT_NAME="${project_name}"
SSM_DOCUMENT="${ssm_document}"

# Logging
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting User Data Script ==="
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_NAME"
echo "SSM Document: $SSM_DOCUMENT"

# Update system
echo "=== Updating system packages ==="
yum update -y

# Install required packages
echo "=== Installing required packages ==="
yum install -y \
    wget \
    curl \
    unzip \
    htop \
    awscli \
    amazon-ssm-agent

# Start and enable SSM Agent
echo "=== Configuring SSM Agent ==="
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Install CloudWatch agent
echo "=== Installing CloudWatch Agent ==="
wget -O /tmp/amazon-cloudwatch-agent.rpm \
    https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U /tmp/amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/var/log/messages",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/user-data",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "AWS/EC2/Custom",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"

# Tag the instance
echo "=== Tagging instance ==="
aws ec2 create-tags \
    --resources $INSTANCE_ID \
    --tags \
        Key=UserDataConfigured,Value=true \
        Key=ConfigurationDate,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --region $REGION

# Install and configure nginx (example web server)
echo "=== Installing and configuring nginx ==="
yum install -y nginx

# Create a simple index page
cat << EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>$PROJECT_NAME - $ENVIRONMENT</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f0f0f0;
        }
        .container { 
            background: white; 
            padding: 20px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header { 
            color: #2c3e50; 
            border-bottom: 2px solid #3498db; 
            padding-bottom: 10px; 
        }
        .info { 
            background: #ecf0f1; 
            padding: 15px; 
            margin: 20px 0; 
            border-radius: 5px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">$PROJECT_NAME - $ENVIRONMENT Environment</h1>
        <div class="info">
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Region:</strong> $REGION</p>
            <p><strong>Environment:</strong> $ENVIRONMENT</p>
            <p><strong>Project:</strong> $PROJECT_NAME</p>
            <p><strong>Configured at:</strong> $(date)</p>
        </div>
        <p>This instance has been automatically configured using AWS Systems Manager and Auto Scaling.</p>
        <p>CloudWatch Agent is running and collecting metrics and logs.</p>
    </div>
</body>
</html>
EOF

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Create a health check endpoint
cat << 'EOF' > /var/www/html/health
OK
EOF

# Set up log rotation for application logs
cat << 'EOF' > /etc/logrotate.d/user-data
/var/log/user-data.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 0644 root root
}
EOF

# Register instance with SSM and run the configuration document if it exists
echo "=== Running SSM configuration document ==="
if [ ! -z "$SSM_DOCUMENT" ] && [ "$SSM_DOCUMENT" != "null" ]; then
    sleep 60  # Wait for SSM agent to be fully ready
    
    # Send command to run the configuration document
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "$SSM_DOCUMENT" \
        --parameters environment=$ENVIRONMENT \
        --region $REGION \
        --comment "Auto-configuration via user data" || true
else
    echo "No SSM document specified, skipping SSM configuration"
fi

# Create a completion marker
echo "=== User Data Script Completed Successfully ===" 
date > /tmp/user-data-completed

echo "=== User Data Script finished ==="