package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test de l'infrastructure complète
func TestAWSAutomationInfrastructure(t *testing.T) {
	t.Parallel()

	// Configuration Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Chemin vers la configuration Terraform
		TerraformDir: "../",

		// Variables à passer à Terraform
		Vars: map[string]interface{}{
			"aws_region":   "us-west-2",
			"environment":  "test",
			"project_name": "aws-automation-test",
			"owner":        "terratest",
			// Utilisez des valeurs de test sécurisées
			"directory_password":         "TestPassword123!",
			"database_connection_string": "postgresql://localhost:5432/testdb",
			"primary_api_key":           "test-primary-key",
			"secondary_api_key":         "test-secondary-key",
		},

		// Retry settings
		RetryableTerraformErrors: map[string]string{
			"timeout while waiting for state to become": "AWS is eventually consistent",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
	})

	// Cleanup après les tests
	defer terraform.Destroy(t, terraformOptions)

	// Apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Tests des outputs
	testVPCOutput(t, terraformOptions)
	testLambdaOutput(t, terraformOptions)
	testSSMOutput(t, terraformOptions)
	testAutoScalingOutput(t, terraformOptions)
	testDirectoryOutput(t, terraformOptions)
}

func testVPCOutput(t *testing.T, terraformOptions *terraform.Options) {
	// Vérifier que le VPC a été créé
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID ne devrait pas être vide")
	assert.Contains(t, vpcID, "vpc-", "VPC ID devrait commencer par 'vpc-'")

	// Vérifier les sous-réseaux publics
	publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.NotEmpty(t, publicSubnets, "Au moins un sous-réseau public devrait exister")
	assert.GreaterOrEqual(t, len(publicSubnets), 1, "Au moins un sous-réseau public devrait être créé")

	// Vérifier les sous-réseaux privés
	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.NotEmpty(t, privateSubnets, "Au moins un sous-réseau privé devrait exister")
	assert.GreaterOrEqual(t, len(privateSubnets), 1, "Au moins un sous-réseau privé devrait être créé")
}

func testLambdaOutput(t *testing.T, terraformOptions *terraform.Options) {
	// Vérifier la fonction Lambda
	lambdaArn := terraform.Output(t, terraformOptions, "lambda_function_arn")
	assert.NotEmpty(t, lambdaArn, "Lambda ARN ne devrait pas être vide")
	assert.Contains(t, lambdaArn, "arn:aws:lambda:", "Lambda ARN devrait être un ARN AWS valide")

	lambdaName := terraform.Output(t, terraformOptions, "lambda_function_name")
	assert.NotEmpty(t, lambdaName, "Lambda name ne devrait pas être vide")
	assert.Contains(t, lambdaName, "aws-automation-test", "Lambda name devrait contenir le nom du projet")
}

func testSSMOutput(t *testing.T, terraformOptions *terraform.Options) {
	// Vérifier le document SSM
	ssmDocumentName := terraform.Output(t, terraformOptions, "ssm_document_name")
	assert.NotEmpty(t, ssmDocumentName, "SSM document name ne devrait pas être vide")
	assert.Contains(t, ssmDocumentName, "aws-automation-test", "SSM document devrait contenir le nom du projet")

	// Vérifier les paramètres SSM
	ssmParameters := terraform.OutputList(t, terraformOptions, "ssm_parameter_names")
	assert.NotEmpty(t, ssmParameters, "Au moins un paramètre SSM devrait exister")
	assert.GreaterOrEqual(t, len(ssmParameters), 3, "Au moins 3 paramètres SSM devraient être créés")

	// Vérifier le bucket S3 pour les logs SSM
	s3Bucket := terraform.Output(t, terraformOptions, "ssm_s3_bucket")
	assert.NotEmpty(t, s3Bucket, "S3 bucket pour SSM ne devrait pas être vide")
	assert.Contains(t, s3Bucket, "aws-automation-test", "S3 bucket devrait contenir le nom du projet")
}

func testAutoScalingOutput(t *testing.T, terraformOptions *terraform.Options) {
	// Vérifier l'Auto Scaling Group
	asgName := terraform.Output(t, terraformOptions, "autoscaling_group_name")
	assert.NotEmpty(t, asgName, "Auto Scaling Group name ne devrait pas être vide")
	assert.Contains(t, asgName, "aws-automation-test", "ASG name devrait contenir le nom du projet")

	asgArn := terraform.Output(t, terraformOptions, "autoscaling_group_arn")
	assert.NotEmpty(t, asgArn, "Auto Scaling Group ARN ne devrait pas être vide")
	assert.Contains(t, asgArn, "arn:aws:autoscaling:", "ASG ARN devrait être un ARN AWS valide")
}

func testDirectoryOutput(t *testing.T, terraformOptions *terraform.Options) {
	// Vérifier le Directory Service
	directoryID := terraform.Output(t, terraformOptions, "directory_id")
	assert.NotEmpty(t, directoryID, "Directory ID ne devrait pas être vide")
	assert.Contains(t, directoryID, "d-", "Directory ID devrait commencer par 'd-'")

	// Vérifier les DNS IPs
	dnsIPs := terraform.OutputList(t, terraformOptions, "directory_dns_ips")
	assert.NotEmpty(t, dnsIPs, "Directory DNS IPs ne devraient pas être vides")
	assert.GreaterOrEqual(t, len(dnsIPs), 2, "Au moins 2 DNS IPs devraient être fournis")

	// Vérifier l'URL d'accès
	accessURL := terraform.Output(t, terraformOptions, "directory_access_url")
	assert.NotEmpty(t, accessURL, "Directory access URL ne devrait pas être vide")
	assert.Contains(t, accessURL, "awsapps.com", "Access URL devrait contenir 'awsapps.com'")
}

// Test unitaire pour valider la configuration Terraform
func TestTerraformValidation(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	// Test de validation Terraform
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// Test des variables obligatoires
func TestRequiredVariables(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			// Test avec des variables manquantes pour vérifier la validation
			"aws_region": "us-west-2",
		},
	}

	// Ce test devrait échouer car des variables obligatoires manquent
	terraform.Init(t, terraformOptions)
	
	// Vérifier que la planification échoue avec des variables manquantes
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err, "La planification devrait échouer avec des variables manquantes")
}