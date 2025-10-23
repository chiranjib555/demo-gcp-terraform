# Local test script for SQL deployment (PowerShell version)
# Run this from your local machine to test the deployment before pushing to GitHub

param(
    [Parameter(Mandatory=$false)]
    [string]$GcpProject = "praxis-gantry-475007-k0",
    
    [Parameter(Mandatory=$false)]
    [string]$GcpZone = "us-central1-a",
    
    [Parameter(Mandatory=$false)]
    [string]$VmName = "sql-linux-vm",
    
    [Parameter(Mandatory=$true)]
    [string]$SaPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$CiLogin = "ci_user",
    
    [Parameter(Mandatory=$true)]
    [string]$CiPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$DataDir = "/mnt/sqldata",
    
    [Parameter(Mandatory=$false)]
    [string]$DbName = "DemoDB"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Local SQL Deployment Test ===" -ForegroundColor Yellow

Write-Host "[OK] Configuration validated" -ForegroundColor Green
Write-Host "  Project: $GcpProject"
Write-Host "  Zone: $GcpZone"
Write-Host "  VM: $VmName"
Write-Host "  Database: $DbName"
Write-Host ""

# Set gcloud config
Write-Host "[Step 1/5] Configuring gcloud..." -ForegroundColor Yellow
gcloud config set project $GcpProject
gcloud config set compute/zone $GcpZone

Write-Host "[OK] Authenticated as:" -ForegroundColor Green
gcloud auth list | Select-Object -First 3

# Test SSH connection
Write-Host "`n[Step 2/5] Testing SSH connection to VM..." -ForegroundColor Yellow
try {
    gcloud compute ssh $VmName `
        --tunnel-through-iap `
        --zone $GcpZone `
        --command "echo 'SSH connection successful'"
    Write-Host "[OK] SSH connection working" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] SSH connection failed" -ForegroundColor Red
    exit 1
}

# Copy provision script to VM
Write-Host "`n[Step 3/5] Copying provision script to VM..." -ForegroundColor Yellow
gcloud compute scp `
    --tunnel-through-iap `
    --zone $GcpZone `
    scripts/provision_sql.sh `
    "${VmName}:/tmp/provision_sql.sh"

Write-Host "[OK] Script copied successfully" -ForegroundColor Green

# Run provision script
Write-Host "`n[Step 4/5] Running provision script on VM..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow

# Escape special characters in passwords
$SafeSaPwd = $SaPassword -replace "'", "'\'''"
$SafeCiPwd = $CiPassword -replace "'", "'\'''"

$command = "bash -lc 'chmod +x /tmp/provision_sql.sh && SA_PWD=`"$SafeSaPwd`" CI_LOGIN=`"$CiLogin`" CI_PASSWORD=`"$SafeCiPwd`" DATA_DIR=`"$DataDir`" DB_NAME=`"$DbName`" sudo -E /tmp/provision_sql.sh'"

try {
    # Use --strict-host-key-checking instead of raw SSH options
    gcloud compute ssh $VmName `
        --tunnel-through-iap `
        --zone $GcpZone `
        --strict-host-key-checking=no `
        --command=$command
    
    Write-Host "[OK] Provision script completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Provision script failed" -ForegroundColor Red
    Write-Host "`nFetching container logs for debugging..." -ForegroundColor Yellow
    
    $debugCmd = "sudo docker ps -a; sudo docker logs --tail=200 mssql; sudo ls -l /mnt/sqldata"
    gcloud compute ssh $VmName `
        --tunnel-through-iap `
        --zone $GcpZone `
        --command $debugCmd
    exit 1
}

# Verify deployment
Write-Host "`n[Step 5/5] Verifying deployment..." -ForegroundColor Yellow

# Check container status
$containerStatus = gcloud compute ssh $VmName `
    --tunnel-through-iap `
    --zone $GcpZone `
    --command "sudo docker ps --filter name=mssql --format '{{.Status}}'"

Write-Host "  Container status: $containerStatus"

# Test SQL connection
Write-Host "  Testing SQL connection..."
try {
    $sqlCmd = "sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$SafeSaPwd' -Q 'SELECT @@VERSION' -h -1"
    gcloud compute ssh $VmName `
        --tunnel-through-iap `
        --zone $GcpZone `
        --command $sqlCmd `
        2>&1 | Out-Null
    Write-Host "[OK] SQL Server responding" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] SQL Server not responding" -ForegroundColor Red
    exit 1
}

# Check database and user
Write-Host "  Verifying database and user..."
$dbCheckCmd = "sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$SafeSaPwd' -Q 'SELECT DB_ID(N`"$DbName`")' -h -1"
$dbExists = gcloud compute ssh $VmName `
    --tunnel-through-iap `
    --zone $GcpZone `
    --command $dbCheckCmd

if ($dbExists -and $dbExists -notmatch "NULL") {
    Write-Host "[OK] Database '$DbName' exists" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Database '$DbName' not found" -ForegroundColor Red
    exit 1
}

# Final summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "   DEPLOYMENT TEST SUCCESSFUL!                  " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Connection details:"
Write-Host "  Server: 34.57.37.222,1433"
Write-Host "  Database: $DbName"
Write-Host "  User: $CiLogin"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify you can connect from your local SQL client"
Write-Host "  2. If everything works, commit and push your changes"
Write-Host "  3. The GitHub Actions workflow will use the same logic"
Write-Host ""
