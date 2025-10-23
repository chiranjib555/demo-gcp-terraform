#!/bin/bash

###############################################################################
# SQL Server VM Connection Information Retrieval Script
# 
# Purpose: Fetch current VM IP address and generate connection strings
# Usage: ./scripts/get-connection-info.sh [project-id] [zone]
#
# This script is useful for:
#   - Getting current connection details after VM recreate
#   - Updating application configuration files
#   - Generating connection strings for different tools
###############################################################################

set -euo pipefail

# Configuration (can be overridden by arguments)
PROJECT_ID="${1:-praxis-gantry-475007-k0}"
ZONE="${2:-us-central1-a}"
VM_NAME="sql-linux-vm"
DATABASE="DemoDB"
SQL_USER="ci_user"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         SQL Server VM Connection Information                       ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Set project
gcloud config set project "$PROJECT_ID" --quiet

# Check if VM exists
if ! gcloud compute instances describe "$VM_NAME" --zone "$ZONE" &>/dev/null; then
    echo -e "${RED}❌ VM does not exist!${NC}"
    echo ""
    echo "The VM has been destroyed. To recreate it:"
    echo "  1. Run GitHub Actions workflow with 'create' action"
    echo "  2. Or use: cd infra && terraform apply"
    exit 1
fi

# Get VM status
VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone "$ZONE" --format="value(status)")

echo -e "${CYAN}📊 VM Status:${NC}"
echo "   Name: $VM_NAME"
echo "   Zone: $ZONE"
echo -e "   Status: ${GREEN}$VM_STATUS${NC}"
echo ""

# Get IP addresses
EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone "$ZONE" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")

INTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone "$ZONE" \
    --format="get(networkInterfaces[0].networkIP)" 2>/dev/null || echo "N/A")

echo -e "${CYAN}🌐 Network Information:${NC}"
echo "   External IP: $EXTERNAL_IP"
echo "   Internal IP: $INTERNAL_IP"
echo "   SQL Port: 1433"
echo ""

# Check if VM is running
if [ "$VM_STATUS" != "RUNNING" ]; then
    echo -e "${YELLOW}⚠️ VM is not running. Start it first to connect.${NC}"
    echo ""
    echo "To start the VM:"
    echo "  gcloud compute instances start $VM_NAME --zone $ZONE"
    exit 0
fi

# Generate connection strings
echo -e "${CYAN}🔌 Connection Strings:${NC}"
echo ""

echo -e "${YELLOW}ADO.NET / C# / .NET:${NC}"
echo "Server=${EXTERNAL_IP},1433;Database=${DATABASE};User Id=${SQL_USER};Password=<YOUR_PASSWORD>;TrustServerCertificate=True;Encrypt=True;"
echo ""

echo -e "${YELLOW}JDBC / Java:${NC}"
echo "jdbc:sqlserver://${EXTERNAL_IP}:1433;databaseName=${DATABASE};user=${SQL_USER};password=<YOUR_PASSWORD>;encrypt=true;trustServerCertificate=true;"
echo ""

echo -e "${YELLOW}ODBC:${NC}"
echo "Driver={ODBC Driver 18 for SQL Server};Server=${EXTERNAL_IP},1433;Database=${DATABASE};Uid=${SQL_USER};Pwd=<YOUR_PASSWORD>;Encrypt=yes;TrustServerCertificate=yes;"
echo ""

echo -e "${YELLOW}SQLAlchemy / Python:${NC}"
echo "mssql+pyodbc://${SQL_USER}:<YOUR_PASSWORD>@${EXTERNAL_IP}:1433/${DATABASE}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
echo ""

echo -e "${YELLOW}Azure Data Studio / SSMS:${NC}"
echo "Server: ${EXTERNAL_IP},1433"
echo "Database: ${DATABASE}"
echo "Authentication: SQL Server Authentication"
echo "Username: ${SQL_USER}"
echo "Password: <YOUR_PASSWORD>"
echo "Encryption: Mandatory"
echo "Trust server certificate: Yes"
echo ""

# Test connection (requires sqlcmd to be installed locally)
echo -e "${CYAN}🧪 Testing Connection:${NC}"
if command -v sqlcmd &> /dev/null; then
    echo "Testing connection to SQL Server..."
    
    # Note: This requires SQL password from Secret Manager
    if gcloud secrets versions access latest --secret=sql-ci-password --project="$PROJECT_ID" &>/dev/null; then
        SQL_PASSWORD=$(gcloud secrets versions access latest --secret=sql-ci-password --project="$PROJECT_ID")
        
        if sqlcmd -S "${EXTERNAL_IP},1433" -U "$SQL_USER" -P "$SQL_PASSWORD" -C -Q "SELECT @@VERSION" &>/dev/null; then
            echo -e "${GREEN}✅ Connection successful!${NC}"
        else
            echo -e "${YELLOW}⚠️ Connection failed. VM might still be starting up.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Cannot fetch password from Secret Manager${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ sqlcmd not installed locally, skipping connection test${NC}"
    echo "To test manually:"
    echo "  sqlcmd -S ${EXTERNAL_IP},1433 -U ${SQL_USER} -P <PASSWORD> -C -Q 'SELECT @@VERSION'"
fi

echo ""
echo -e "${GREEN}✅ Connection information retrieved successfully!${NC}"
echo ""

# Export as environment variables (for scripting)
echo -e "${CYAN}📝 Environment Variables (copy to .env):${NC}"
echo "SQL_SERVER_HOST=${EXTERNAL_IP}"
echo "SQL_SERVER_PORT=1433"
echo "SQL_SERVER_DATABASE=${DATABASE}"
echo "SQL_SERVER_USER=${SQL_USER}"
echo "SQL_SERVER_PASSWORD=<get from Secret Manager: sql-ci-password>"
echo ""

# Generate JSON output (for automation)
echo -e "${CYAN}📋 JSON Output (for automation):${NC}"
cat << EOF
{
  "vm_name": "$VM_NAME",
  "status": "$VM_STATUS",
  "zone": "$ZONE",
  "external_ip": "$EXTERNAL_IP",
  "internal_ip": "$INTERNAL_IP",
  "database": "$DATABASE",
  "username": "$SQL_USER",
  "port": 1433,
  "connection_string": "Server=${EXTERNAL_IP},1433;Database=${DATABASE};User Id=${SQL_USER};Password=<PASSWORD>;TrustServerCertificate=True;"
}
EOF
echo ""
