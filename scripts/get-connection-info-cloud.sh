#!/bin/bash

###############################################################################
# SQL Server VM Connection Information - Cloud Shell Version
# 
# Purpose: Fetch VM IP and generate connection strings from anywhere
# Usage: Run this in GCP Cloud Shell (no local setup needed)
#
# HOW TO USE:
#   1. Go to: https://console.cloud.google.com
#   2. Click the Cloud Shell icon (top right)
#   3. Run: curl -s https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh | bash
#
# OR download and run:
#   gsutil cp gs://praxis-sql-bootstrap/get-connection-info-cloud.sh .
#   chmod +x get-connection-info-cloud.sh
#   ./get-connection-info-cloud.sh
###############################################################################

set -euo pipefail

# Configuration
PROJECT_ID="${1:-praxis-gantry-475007-k0}"
ZONE="${2:-us-central1-a}"
VM_NAME="sql-linux-vm"
DATABASE="DemoDB"
SQL_USER="ci_user"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         SQL Server VM Connection Information (Cloud Shell)         ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Set project
echo "Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID" --quiet

# Check if VM exists
echo ""
echo "Checking if VM exists..."
if ! gcloud compute instances describe "$VM_NAME" --zone "$ZONE" &>/dev/null; then
    echo -e "${RED}❌ VM does not exist!${NC}"
    echo ""
    echo "The VM has been destroyed. To recreate it:"
    echo "  Option 1: GitHub Actions → Run workflow with 'create' action"
    echo "  Option 2: Cloud Shell → cd to Terraform folder and run:"
    echo "            git clone https://github.com/chiranjib555/demo-gcp-terraform.git"
    echo "            cd demo-gcp-terraform/infra"
    echo "            terraform init"
    echo "            terraform apply -target=google_compute_instance.sqlvm"
    exit 1
fi

# Get VM status
VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone "$ZONE" --format="value(status)")

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 VM STATUS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo "   VM Name:      $VM_NAME"
echo "   Project:      $PROJECT_ID"
echo "   Zone:         $ZONE"
echo -e "   Status:       ${GREEN}$VM_STATUS${NC}"

# Get IP addresses
EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone "$ZONE" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")

INTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone "$ZONE" \
    --format="get(networkInterfaces[0].networkIP)" 2>/dev/null || echo "N/A")

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🌐 NETWORK INFORMATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo "   External IP:  $EXTERNAL_IP"
echo "   Internal IP:  $INTERNAL_IP"
echo "   SQL Port:     1433"

# Check if VM is running
if [ "$VM_STATUS" != "RUNNING" ]; then
    echo ""
    echo -e "${YELLOW}⚠️ WARNING: VM is not running!${NC}"
    echo ""
    echo "To start the VM:"
    echo "  gcloud compute instances start $VM_NAME --zone $ZONE"
    echo ""
    echo "Or use GitHub Actions: Run workflow with 'restart' action"
    exit 0
fi

# Generate connection strings
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔌 CONNECTION STRINGS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}▶ ADO.NET / C# / .NET:${NC}"
echo "Server=${EXTERNAL_IP},1433;Database=${DATABASE};User Id=${SQL_USER};Password=<PASSWORD>;TrustServerCertificate=True;Encrypt=True;"
echo ""

echo -e "${YELLOW}▶ JDBC / Java:${NC}"
echo "jdbc:sqlserver://${EXTERNAL_IP}:1433;databaseName=${DATABASE};user=${SQL_USER};password=<PASSWORD>;encrypt=true;trustServerCertificate=true;"
echo ""

echo -e "${YELLOW}▶ ODBC:${NC}"
echo "Driver={ODBC Driver 18 for SQL Server};Server=${EXTERNAL_IP},1433;Database=${DATABASE};Uid=${SQL_USER};Pwd=<PASSWORD>;Encrypt=yes;TrustServerCertificate=yes;"
echo ""

echo -e "${YELLOW}▶ SQLAlchemy / Python:${NC}"
echo "mssql+pyodbc://${SQL_USER}:<PASSWORD>@${EXTERNAL_IP}:1433/${DATABASE}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
echo ""

echo -e "${YELLOW}▶ Azure Data Studio / SSMS:${NC}"
echo "  Server:         ${EXTERNAL_IP},1433"
echo "  Database:       ${DATABASE}"
echo "  Authentication: SQL Server Authentication"
echo "  Username:       ${SQL_USER}"
echo "  Password:       <Get from Secret Manager>"
echo "  Encryption:     Mandatory"
echo "  Trust Cert:     Yes"
echo ""

# Get password from Secret Manager
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔑 SQL PASSWORD${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "To retrieve the password:"
echo -e "${YELLOW}gcloud secrets versions access latest --secret=sql-ci-password --project=$PROJECT_ID${NC}"
echo ""

# Test connection
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🧪 CONNECTION TEST${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

if command -v sqlcmd &> /dev/null; then
    echo "Testing connection to SQL Server..."
    
    if SQL_PASSWORD=$(gcloud secrets versions access latest --secret=sql-ci-password --project="$PROJECT_ID" 2>/dev/null); then
        if sqlcmd -S "${EXTERNAL_IP},1433" -U "$SQL_USER" -P "$SQL_PASSWORD" -C -Q "SELECT @@VERSION AS 'SQL Server Version', DB_NAME() AS 'Current Database'" 2>/dev/null; then
            echo ""
            echo -e "${GREEN}✅ Connection test SUCCESSFUL!${NC}"
        else
            echo -e "${YELLOW}⚠️ Connection failed. Possible reasons:${NC}"
            echo "   • SQL Server is still starting up (wait 1-2 minutes)"
            echo "   • Firewall blocking connection"
            echo "   • Password mismatch"
        fi
    else
        echo -e "${YELLOW}⚠️ Cannot fetch password from Secret Manager${NC}"
        echo "Make sure you have permission to access secrets."
    fi
else
    echo -e "${YELLOW}ℹ️ sqlcmd not available in Cloud Shell (expected)${NC}"
    echo ""
    echo "To test connection manually from your local machine:"
    echo "  1. Install SQL Server command-line tools"
    echo "  2. Get password: gcloud secrets versions access latest --secret=sql-ci-password"
    echo "  3. Test: sqlcmd -S ${EXTERNAL_IP},1433 -U ${SQL_USER} -P <PASSWORD> -C -Q 'SELECT 1'"
fi

# JSON output for automation
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 JSON OUTPUT (for automation/scripts)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
cat << EOF
{
  "vm_name": "$VM_NAME",
  "project_id": "$PROJECT_ID",
  "zone": "$ZONE",
  "status": "$VM_STATUS",
  "external_ip": "$EXTERNAL_IP",
  "internal_ip": "$INTERNAL_IP",
  "database": "$DATABASE",
  "username": "$SQL_USER",
  "port": 1433,
  "connection_string_template": "Server=${EXTERNAL_IP},1433;Database=${DATABASE};User Id=${SQL_USER};Password=<PASSWORD>;TrustServerCertificate=True;",
  "password_command": "gcloud secrets versions access latest --secret=sql-ci-password --project=$PROJECT_ID"
}
EOF

echo ""
echo ""
echo -e "${GREEN}✅ Connection information retrieved successfully!${NC}"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "💡 Quick Actions:"
echo ""
echo "  Get password:"
echo "    gcloud secrets versions access latest --secret=sql-ci-password"
echo ""
echo "  Start VM (if stopped):"
echo "    gcloud compute instances start $VM_NAME --zone $ZONE"
echo ""
echo "  Check VM logs:"
echo "    gcloud compute instances get-serial-port-output $VM_NAME --zone $ZONE | tail -50"
echo ""
echo "  SSH into VM:"
echo "    gcloud compute ssh $VM_NAME --zone $ZONE --tunnel-through-iap"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo ""
