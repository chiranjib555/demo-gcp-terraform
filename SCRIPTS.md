# Infrastructure Management Scripts

## PowerShell Scripts for Windows

### teardown.ps1 - Destroy VM (Keep Data Safe)
```powershell
# Save to: teardown.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== Tearing Down SQL VM ===" -ForegroundColor Yellow
Write-Host "Data will be preserved on persistent disk" -ForegroundColor Green

Set-Location -Path "$PSScriptRoot\infra"

# Only destroy the VM instance
terraform destroy -target=google_compute_instance.sqlvm -auto-approve

Write-Host ""
Write-Host "✅ VM destroyed successfully!" -ForegroundColor Green
Write-Host "💾 Your data is safe on the persistent disk" -ForegroundColor Cyan
Write-Host "💰 You're now saving ~`$1.50/day on compute costs" -ForegroundColor Green
Write-Host ""
Write-Host "To spin up again, run: .\spinup.ps1" -ForegroundColor Yellow
```

### spinup.ps1 - Recreate VM
```powershell
# Save to: spinup.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== Spinning Up SQL VM ===" -ForegroundColor Yellow

Set-Location -Path "$PSScriptRoot\infra"

# Apply infrastructure
terraform apply -auto-approve

$VM_IP = terraform output -raw sqlvm_external_ip

Write-Host ""
Write-Host "✅ VM is up and running!" -ForegroundColor Green
Write-Host "🌐 IP Address: $VM_IP" -ForegroundColor Cyan
Write-Host "📦 Persistent disk automatically reattached" -ForegroundColor Green
Write-Host ""
Write-Host "⏳ Next steps:" -ForegroundColor Yellow
Write-Host "  1. Wait ~2 minutes for startup script to complete" -ForegroundColor White
Write-Host "  2. Deploy SQL Server via GitHub Actions" -ForegroundColor White
Write-Host "  3. Go to: https://github.com/YOUR_REPO/actions" -ForegroundColor White
Write-Host "  4. Run workflow: 'Deploy SQL Server to GCP'" -ForegroundColor White
Write-Host ""
Write-Host "Or deploy manually via SSH:" -ForegroundColor Yellow
Write-Host "  gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap" -ForegroundColor Gray
```

### check-status.ps1 - Check VM and SQL Server Status
```powershell
# Save to: check-status.ps1
param(
    [string]$ProjectId = "praxis-gantry-475007-k0",
    [string]$Zone = "us-central1-a",
    [string]$VmName = "sql-linux-vm"
)

Write-Host "=== Checking Infrastructure Status ===" -ForegroundColor Yellow
Write-Host ""

# Check VM status
Write-Host "📊 VM Status:" -ForegroundColor Cyan
$vmStatus = gcloud compute instances describe $VmName `
    --project=$ProjectId `
    --zone=$Zone `
    --format="value(status)" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  VM: $vmStatus" -ForegroundColor Green
    
    # Get IP
    $vmIp = gcloud compute instances describe $VmName `
        --project=$ProjectId `
        --zone=$Zone `
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
    Write-Host "  IP: $vmIp" -ForegroundColor White
} else {
    Write-Host "  VM: NOT FOUND (possibly destroyed)" -ForegroundColor Red
}

Write-Host ""

# Check disk status
Write-Host "💾 Persistent Disk Status:" -ForegroundColor Cyan
$diskStatus = gcloud compute disks describe sql-data-disk `
    --project=$ProjectId `
    --zone=$Zone `
    --format="value(status,sizeGb)" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Disk: $diskStatus" -ForegroundColor Green
} else {
    Write-Host "  Disk: NOT FOUND" -ForegroundColor Red
}

Write-Host ""

# If VM is running, check Docker and SQL Server
if ($vmStatus -eq "RUNNING") {
    Write-Host "🐳 Docker Status:" -ForegroundColor Cyan
    
    $dockerStatus = gcloud compute ssh $VmName `
        --project=$ProjectId `
        --zone=$Zone `
        --tunnel-through-iap `
        --command="sudo docker ps --filter name=mssql --format '{{.Status}}'" 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $dockerStatus) {
        Write-Host "  Container: $dockerStatus" -ForegroundColor Green
        
        # Check SQL Server connectivity
        Write-Host ""
        Write-Host "🗄️  SQL Server Status:" -ForegroundColor Cyan
        
        $sqlCheck = gcloud compute ssh $VmName `
            --project=$ProjectId `
            --zone=$Zone `
            --tunnel-through-iap `
            --command="sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '$env:SQL_SA_PASSWORD' -C -Q 'SELECT @@VERSION' 2>&1" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  SQL Server: RUNNING" -ForegroundColor Green
            Write-Host "  Connection: OK" -ForegroundColor Green
        } else {
            Write-Host "  SQL Server: UNKNOWN (might be starting up)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Container: NOT RUNNING" -ForegroundColor Yellow
        Write-Host "  ⚠️  Run GitHub Actions workflow to deploy SQL Server" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Status Check Complete ===" -ForegroundColor Green
```

### update-ip.ps1 - Update Firewall for New IP
```powershell
# Save to: update-ip.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== Updating Firewall Rules for New IP ===" -ForegroundColor Yellow

# Get current public IP
$currentIp = (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
Write-Host "Your current IP: $currentIp" -ForegroundColor Cyan

# Update terraform.tfvars
$tfvarsPath = "$PSScriptRoot\infra\terraform.tfvars"
$content = Get-Content $tfvarsPath -Raw

# Replace admin_ip_cidr value
$newContent = $content -replace 'admin_ip_cidr\s*=\s*"[^"]*"', "admin_ip_cidr = `"$currentIp/32`""
$newContent | Set-Content -Path $tfvarsPath -NoNewline

Write-Host "Updated terraform.tfvars with new IP" -ForegroundColor Green

# Apply changes
Set-Location -Path "$PSScriptRoot\infra"
Write-Host "Applying firewall changes..." -ForegroundColor Yellow
terraform apply -auto-approve

Write-Host ""
Write-Host "✅ Firewall updated successfully!" -ForegroundColor Green
Write-Host "You can now connect from: $currentIp" -ForegroundColor Cyan
```

---

## Bash Scripts for Linux/Mac

### teardown.sh
```bash
#!/bin/bash
set -e

echo "=== Tearing Down SQL VM ==="
echo "Data will be preserved on persistent disk"

cd "$(dirname "$0")/infra"

terraform destroy -target=google_compute_instance.sqlvm -auto-approve

echo ""
echo "✅ VM destroyed successfully!"
echo "💾 Your data is safe on the persistent disk"
echo "💰 You're now saving ~\$1.50/day on compute costs"
echo ""
echo "To spin up again, run: ./spinup.sh"
```

### spinup.sh
```bash
#!/bin/bash
set -e

echo "=== Spinning Up SQL VM ==="

cd "$(dirname "$0")/infra"

terraform apply -auto-approve

VM_IP=$(terraform output -raw sqlvm_external_ip)

echo ""
echo "✅ VM is up and running!"
echo "🌐 IP Address: $VM_IP"
echo "📦 Persistent disk automatically reattached"
echo ""
echo "⏳ Next steps:"
echo "  1. Wait ~2 minutes for startup script to complete"
echo "  2. Deploy SQL Server via GitHub Actions"
echo "  3. Or manually: gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap"
```

### check-status.sh
```bash
#!/bin/bash

PROJECT_ID="praxis-gantry-475007-k0"
ZONE="us-central1-a"
VM_NAME="sql-linux-vm"

echo "=== Checking Infrastructure Status ==="
echo ""

echo "📊 VM Status:"
VM_STATUS=$(gcloud compute instances describe $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --format="value(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" != "NOT_FOUND" ]; then
    echo "  VM: $VM_STATUS"
    VM_IP=$(gcloud compute instances describe $VM_NAME \
        --project=$PROJECT_ID \
        --zone=$ZONE \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    echo "  IP: $VM_IP"
else
    echo "  VM: NOT FOUND (possibly destroyed)"
fi

echo ""
echo "💾 Persistent Disk Status:"
gcloud compute disks describe sql-data-disk \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --format="value(status,sizeGb)" 2>/dev/null || echo "  Disk: NOT FOUND"

if [ "$VM_STATUS" = "RUNNING" ]; then
    echo ""
    echo "🐳 Docker Status:"
    gcloud compute ssh $VM_NAME \
        --project=$PROJECT_ID \
        --zone=$ZONE \
        --tunnel-through-iap \
        --command="sudo docker ps --filter name=mssql" 2>/dev/null || echo "  Container: NOT RUNNING"
fi

echo ""
echo "=== Status Check Complete ==="
```

### update-ip.sh
```bash
#!/bin/bash
set -e

echo "=== Updating Firewall Rules for New IP ==="

CURRENT_IP=$(curl -s ifconfig.me)
echo "Your current IP: $CURRENT_IP"

cd "$(dirname "$0")/infra"

# Update terraform.tfvars
sed -i.bak "s|admin_ip_cidr *= *\"[^\"]*\"|admin_ip_cidr = \"$CURRENT_IP/32\"|" terraform.tfvars

echo "Updated terraform.tfvars with new IP"
echo "Applying firewall changes..."

terraform apply -auto-approve

echo ""
echo "✅ Firewall updated successfully!"
echo "You can now connect from: $CURRENT_IP"
```

---

## Usage

### Initial Setup
```powershell
# Windows
.\spinup.ps1
```

### Tear Down for the Night
```powershell
# Windows
.\teardown.ps1
```

### Check Status
```powershell
# Windows
.\check-status.ps1
```

### IP Changed? Update Firewall
```powershell
# Windows
.\update-ip.ps1
```

---

## Make Scripts Executable (Linux/Mac)

```bash
chmod +x teardown.sh spinup.sh check-status.sh update-ip.sh
```

---

## Scheduled Tear Down/Spin Up (Optional)

### Windows Task Scheduler

**Tear down at 6 PM:**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\teardown.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 6PM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GCP SQL Teardown" -Description "Destroy SQL VM to save costs"
```

**Spin up at 8 AM:**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\spinup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 8AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GCP SQL Spinup" -Description "Recreate SQL VM for work day"
```

### Linux/Mac Cron

```bash
# Edit crontab
crontab -e

# Tear down at 6 PM (18:00)
0 18 * * * /path/to/teardown.sh >> /var/log/gcp-teardown.log 2>&1

# Spin up at 8 AM
0 8 * * 1-5 /path/to/spinup.sh >> /var/log/gcp-spinup.log 2>&1
```

---

**Pro Tip:** Combine these scripts with GitHub Actions scheduled workflows for fully automated infrastructure management!
