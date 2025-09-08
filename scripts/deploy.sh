#!/bin/bash

# Script de déploiement pour l'infrastructure AWS Automation
set -e

# Variables
ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Vérifications préalables
check_prerequisites() {
    log "Vérification des prérequis..."
    
    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform n'est pas installé"
    fi
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI n'est pas installé"
    fi
    
    # Vérifier les credentials AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        error "Credentials AWS non configurés ou invalides"
    fi
    
    # Vérifier que le fichier tfvars existe
    if [[ ! -f "environments/${ENVIRONMENT}/terraform.tfvars" ]]; then
        error "Fichier terraform.tfvars manquant pour l'environnement ${ENVIRONMENT}"
    fi
    
    log "✅ Tous les prérequis sont satisfaits"
}

# Initialisation Terraform
init_terraform() {
    log "Initialisation de Terraform pour l'environnement ${ENVIRONMENT}..."
    
    terraform init \
        -backend-config="environments/${ENVIRONMENT}/backend.tf" \
        -reconfigure
    
    log "✅ Terraform initialisé"
}

# Validation de la configuration
validate_terraform() {
    log "Validation de la configuration Terraform..."
    
    terraform validate
    
    log "✅ Configuration validée"
}

# Format du code
format_terraform() {
    log "Formatage du code Terraform..."
    
    terraform fmt -recursive
    
    log "✅ Code formaté"
}

# Plan Terraform
plan_terraform() {
    log "Génération du plan Terraform pour ${ENVIRONMENT}..."
    
    terraform plan \
        -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
        -out="${ENVIRONMENT}.tfplan"
    
    log "✅ Plan généré: ${ENVIRONMENT}.tfplan"
}

# Apply Terraform
apply_terraform() {
    log "Application du plan Terraform pour ${ENVIRONMENT}..."
    
    if [[ -f "${ENVIRONMENT}.tfplan" ]]; then
        terraform apply "${ENVIRONMENT}.tfplan"
        rm "${ENVIRONMENT}.tfplan"
    else
        warn "Aucun plan trouvé, exécution directe de l'apply..."
        terraform apply \
            -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
            -auto-approve
    fi
    
    log "✅ Infrastructure déployée"
}

# Destroy Terraform
destroy_terraform() {
    warn "⚠️  ATTENTION: Vous êtes sur le point de DÉTRUIRE l'infrastructure ${ENVIRONMENT}"
    read -p "Êtes-vous sûr? (tapez 'yes' pour confirmer): " confirm
    
    if [[ $confirm == "yes" ]]; then
        log "Destruction de l'infrastructure ${ENVIRONMENT}..."
        
        terraform destroy \
            -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
            -auto-approve
        
        log "✅ Infrastructure détruite"
    else
        log "Destruction annulée"
    fi
}

# Affichage des outputs
show_outputs() {
    log "Affichage des outputs Terraform..."
    
    terraform output -json > "${ENVIRONMENT}-outputs.json"
    terraform output
    
    log "✅ Outputs sauvegardés dans ${ENVIRONMENT}-outputs.json"
}

# Menu principal
main() {
    log "🚀 Déploiement AWS Automation Infrastructure"
    log "Environnement: ${ENVIRONMENT}"
    log "Action: ${ACTION}"
    
    check_prerequisites
    init_terraform
    validate_terraform
    format_terraform
    
    case $ACTION in
        "plan")
            plan_terraform
            ;;
        "apply")
            plan_terraform
            apply_terraform
            show_outputs
            ;;
        "destroy")
            destroy_terraform
            ;;
        "validate")
            log "✅ Validation terminée"
            ;;
        *)
            error "Action non reconnue: ${ACTION}. Utilisez: plan, apply, destroy, ou validate"
            ;;
    esac
    
    log "🎉 Opération terminée avec succès!"
}

# Usage
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <environnement> <action>"
    echo "Environnements: dev, staging, prod"
    echo "Actions: plan, apply, destroy, validate"
    echo ""
    echo "Exemples:"
    echo "  $0 dev plan       # Générer un plan pour dev"
    echo "  $0 dev apply      # Déployer en dev"
    echo "  $0 dev destroy    # Détruire dev"
    exit 1
fi

# Exécution
main