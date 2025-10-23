#!/usr/bin/env bash
set -euo pipefail

# Local test script for SQL deployment
# Run this from your local machine to test the deployment before pushing to GitHub

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Local SQL Deployment Test ===${NC}"

# Configuration - adjust these to match your setup
GCP_PROJECT="${GCP_PROJECT:-praxis-gantry-475007-k0}"
GCP_ZONE="${GCP_ZONE:-us-central1-a}"
VM_NAME="${VM_NAME:-sql-linux-vm}"
SA_PWD="${SA_PWD:-}"
CI_LOGIN="${CI_LOGIN:-ci_user}"
CI_PASSWORD="${CI_PASSWORD:-}"
DATA_DIR="/mnt/sqldata"
DB_NAME="DemoDB"

# Validate required secrets
if [ -z "$SA_PWD" ]; then
  echo -e "${RED}Error: SA_PWD environment variable not set${NC}"
  echo "Usage: SA_PWD='your-sa-password' CI_PASSWORD='your-ci-password' ./test-deploy-local.sh"
  exit 1
fi

if [ -z "$CI_PASSWORD" ]; then
  echo -e "${RED}Error: CI_PASSWORD environment variable not set${NC}"
  echo "Usage: SA_PWD='your-sa-password' CI_PASSWORD='your-ci-password' ./test-deploy-local.sh"
  exit 1
fi

echo -e "${GREEN}✓${NC} Configuration validated"
echo "  Project: $GCP_PROJECT"
echo "  Zone: $GCP_ZONE"
echo "  VM: $VM_NAME"
echo "  Database: $DB_NAME"
echo ""

# Set gcloud config
echo -e "${YELLOW}[Step 1/5] Configuring gcloud...${NC}"
gcloud config set project "$GCP_PROJECT"
gcloud config set compute/zone "$GCP_ZONE"

echo -e "${GREEN}✓${NC} Authenticated as:"
gcloud auth list | head -n 3

# Test SSH connection
echo ""
echo -e "${YELLOW}[Step 2/5] Testing SSH connection to VM...${NC}"
if gcloud compute ssh "$VM_NAME" \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  --command "echo 'SSH connection successful'"; then
  echo -e "${GREEN}✓${NC} SSH connection working"
else
  echo -e "${RED}✗${NC} SSH connection failed"
  exit 1
fi

# Copy provision script to VM
echo ""
echo -e "${YELLOW}[Step 3/5] Copying provision script to VM...${NC}"
gcloud compute scp \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  scripts/provision_sql.sh \
  "$VM_NAME:/tmp/provision_sql.sh"

echo -e "${GREEN}✓${NC} Script copied successfully"

# Run provision script
echo ""
echo -e "${YELLOW}[Step 4/5] Running provision script on VM...${NC}"
echo -e "${YELLOW}This may take 5-10 minutes...${NC}"

gcloud compute ssh "$VM_NAME" \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  -- -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "bash -lc 'chmod +x /tmp/provision_sql.sh && SA_PWD=\"$SA_PWD\" CI_LOGIN=\"$CI_LOGIN\" CI_PASSWORD=\"$CI_PASSWORD\" DATA_DIR=\"$DATA_DIR\" DB_NAME=\"$DB_NAME\" sudo -E /tmp/provision_sql.sh'"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓${NC} Provision script completed successfully"
else
  echo -e "${RED}✗${NC} Provision script failed"
  echo ""
  echo -e "${YELLOW}Fetching container logs for debugging...${NC}"
  gcloud compute ssh "$VM_NAME" \
    --tunnel-through-iap \
    --zone "$GCP_ZONE" \
    -- 'sudo docker ps -a; echo "---- logs ----"; sudo docker logs --tail=200 mssql || true; echo "---- dir ----"; sudo ls -l /mnt/sqldata'
  exit 1
fi

# Verify deployment
echo ""
echo -e "${YELLOW}[Step 5/5] Verifying deployment...${NC}"

# Check container status
CONTAINER_STATUS=$(gcloud compute ssh "$VM_NAME" \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  --command "sudo docker ps --filter name=mssql --format '{{.Status}}'" | tr -d '\r\n')

echo "  Container status: $CONTAINER_STATUS"

# Test SQL connection
echo "  Testing SQL connection..."
if gcloud compute ssh "$VM_NAME" \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  --command "sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$SA_PWD' -Q 'SELECT @@VERSION' -h -1" >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} SQL Server responding"
else
  echo -e "${RED}✗${NC} SQL Server not responding"
  exit 1
fi

# Check database and user
echo "  Verifying database and user..."
DB_EXISTS=$(gcloud compute ssh "$VM_NAME" \
  --tunnel-through-iap \
  --zone "$GCP_ZONE" \
  --command "sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$SA_PWD' -Q 'SELECT DB_ID(N\"$DB_NAME\")' -h -1" | tr -d '\r\n' | xargs)

if [ "$DB_EXISTS" != "NULL" ] && [ -n "$DB_EXISTS" ]; then
  echo -e "${GREEN}✓${NC} Database '$DB_NAME' exists"
else
  echo -e "${RED}✗${NC} Database '$DB_NAME' not found"
  exit 1
fi

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Deployment Test Successful!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Connection details:"
echo "  Server: 34.57.37.222,1433"
echo "  Database: $DB_NAME"
echo "  User: $CI_LOGIN"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Verify you can connect from your local SQL client"
echo "  2. If everything works, commit and push your changes"
echo "  3. The GitHub Actions workflow will use the same logic"
echo ""
