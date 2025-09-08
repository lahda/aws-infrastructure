import json
import boto3
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Main Lambda handler function
    Processes EventBridge events and orchestrates AWS services
    """
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Initialize AWS clients
        ssm_client = boto3.client('ssm')
        autoscaling_client = boto3.client('autoscaling')
        ec2_client = boto3.client('ec2')
        
        # Process the event
        event_source = event.get('source', 'unknown')
        detail_type = event.get('detail-type', 'unknown')
        
        logger.info(f"Processing event from {event_source} with detail-type: {detail_type}")
        
        # Example workflow based on event type
        if detail_type == "Scheduled Event":
            result = handle_scheduled_event(ssm_client, autoscaling_client, ec2_client, event)
        elif detail_type == "EC2 State Change":
            result = handle_ec2_state_change(ssm_client, autoscaling_client, ec2_client, event)
        else:
            result = handle_default_event(ssm_client, autoscaling_client, ec2_client, event)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Event processed successfully',
                'result': result,
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise e

def handle_scheduled_event(ssm_client, autoscaling_client, ec2_client, event):
    """Handle scheduled EventBridge events"""
    logger.info("Handling scheduled event")
    
    # Update SSM Parameter
    update_ssm_parameter(ssm_client)
    
    # Check Auto Scaling Group health
    asg_status = check_autoscaling_group(autoscaling_client)
    
    # Create or update SSM document
    document_result = manage_ssm_document(ssm_client)
    
    return {
        'action': 'scheduled_maintenance',
        'ssm_parameter_updated': True,
        'asg_status': asg_status,
        'document_result': document_result
    }

def handle_ec2_state_change(ssm_client, autoscaling_client, ec2_client, event):
    """Handle EC2 state change events"""
    logger.info("Handling EC2 state change event")
    
    instance_id = event.get('detail', {}).get('instance-id')
    state = event.get('detail', {}).get('state')
    
    if instance_id and state:
        logger.info(f"Instance {instance_id} changed to state: {state}")
        
        if state == 'running':
            # Instance is running, configure it via SSM
            configure_instance_via_ssm(ssm_client, instance_id)
        elif state == 'terminated':
            # Instance terminated, log and potentially scale up
            logger.info(f"Instance {instance_id} terminated")
    
    return {
        'action': 'ec2_state_change',
        'instance_id': instance_id,
        'state': state
    }

def handle_default_event(ssm_client, autoscaling_client, ec2_client, event):
    """Handle default/unknown events"""
    logger.info("Handling default event")
    
    # Basic health checks
    asg_status = check_autoscaling_group(autoscaling_client)
    
    return {
        'action': 'default_processing',
        'asg_status': asg_status
    }

def update_ssm_parameter(ssm_client):
    """Update SSM Parameter Store"""
    try:
        parameter_name = '/aws-automation/last-execution'
        parameter_value = datetime.utcnow().isoformat()
        
        ssm_client.put_parameter(
            Name=parameter_name,
            Value=parameter_value,
            Type='String',
            Overwrite=True,
            Description='Last execution timestamp of automation lambda'
        )
        
        logger.info(f"Updated SSM parameter {parameter_name} with value {parameter_value}")
        return True
        
    except Exception as e:
        logger.error(f"Error updating SSM parameter: {str(e)}")
        return False

def check_autoscaling_group(autoscaling_client):
    """Check Auto Scaling Group status"""
    try:
        # Get all Auto Scaling Groups (filter by tag in real implementation)
        response = autoscaling_client.describe_auto_scaling_groups()
        
        asg_status = []
        for asg in response['AutoScalingGroups']:
            status = {
                'name': asg['AutoScalingGroupName'],
                'desired_capacity': asg['DesiredCapacity'],
                'min_size': asg['MinSize'],
                'max_size': asg['MaxSize'],
                'instances': len(asg['Instances']),
                'healthy_instances': len([i for i in asg['Instances'] if i['HealthStatus'] == 'Healthy'])
            }
            asg_status.append(status)
            logger.info(f"ASG {status['name']}: {status['healthy_instances']}/{status['instances']} healthy")
        
        return asg_status
        
    except Exception as e:
        logger.error(f"Error checking Auto Scaling Groups: {str(e)}")
        return []

def manage_ssm_document(ssm_client):
    """Create or update SSM document"""
    try:
        document_name = 'AWS-Automation-ConfigureInstance'
        document_content = {
            "schemaVersion": "2.2",
            "description": "Configure EC2 instance via Systems Manager",
            "parameters": {
                "environment": {
                    "type": "String",
                    "description": "Environment name",
                    "default": "dev"
                }
            },
            "mainSteps": [
                {
                    "action": "aws:runShellScript",
                    "name": "configureInstance",
                    "inputs": {
                        "runCommand": [
                            "#!/bin/bash",
                            "echo 'Starting instance configuration'",
                            "yum update -y",
                            "yum install -y amazon-cloudwatch-agent",
                            "systemctl enable amazon-cloudwatch-agent",
                            "systemctl start amazon-cloudwatch-agent",
                            "echo 'Instance configuration completed'"
                        ]
                    }
                }
            ]
        }
        
        try:
            # Try to update existing document
            ssm_client.update_document(
                Content=json.dumps(document_content),
                Name=document_name,
                DocumentVersion='$LATEST'
            )
            logger.info(f"Updated SSM document: {document_name}")
            return {'action': 'updated', 'document': document_name}
            
        except ssm_client.exceptions.DocumentDoesNotExistException:
            # Document doesn't exist, create it
            ssm_client.create_document(
                Content=json.dumps(document_content),
                Name=document_name,
                DocumentType='Command',
                DocumentFormat='JSON'
            )
            logger.info(f"Created SSM document: {document_name}")
            return {'action': 'created', 'document': document_name}
            
    except Exception as e:
        logger.error(f"Error managing SSM document: {str(e)}")
        return {'action': 'error', 'message': str(e)}

def configure_instance_via_ssm(ssm_client, instance_id):
    """Configure instance using SSM Run Command"""
    try:
        document_name = 'AWS-Automation-ConfigureInstance'
        
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName=document_name,
            Parameters={
                'environment': ['production']
            },
            Comment=f'Configuring instance {instance_id} via automation'
        )
        
        command_id = response['Command']['CommandId']
        logger.info(f"Sent SSM command {command_id} to instance {instance_id}")
        
        return command_id
        
    except Exception as e:
        logger.error(f"Error configuring instance {instance_id} via SSM: {str(e)}")
        return None