# Backend configuration for development environment
terraform {
  backend "s3" {
    bucket         = "ad-automation123"  # À remplacer par le nom de votre bucket existant
    key            = "aws-automation/dev/terraform.tfstate"
    region         = "us-east-1"  
    encrypt        = true
    use_lockfile = true
   # dynamodb_table = "terraform-state-lock-ad-automation"  # À remplacer par le nom de votre table dynamodb existant
    
    # Optionnel: KMS key pour chiffrer le state
    # kms_key_id = "alias/terraform-state-key"
  }
}