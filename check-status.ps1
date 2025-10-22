param(
    [string]$ProjectId = "praxis-gantry-475007-k0",
    [string]$Zone = "us-central1-a",
    [string]$VmName = "sql-linux-vm"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INFRASTRUCTURE STATUS CHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is installed
try {
    $null = Get-Command gcloud -ErrorAction Stop
} catch {
    Write-Host "❌ gcloud CLI not found. Please install Google Cloud SDK." -ForegroundColor Red
    Write-Host "   Download: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

Write-Host "📊 VM Status:" -ForegroundColor Yellow
Write-Host ""

try {
    $vmInfo = gcloud compute instances describe $VmName `
        --project=$ProjectId `
        --zone=$Zone `
        --format="json" 2>$null | ConvertFrom-Json
    
    $status = $vmInfo.status
    $ip = $vmInfo.networkInterfaces[0].accessConfigs[0].natIP
    
    if ($status -eq "RUNNING") {
        Write-Host "  VM: " -NoNewline -ForegroundColor White
        Write-Host "RUNNING ✅" -ForegroundColor Green
        Write-Host "  IP: $ip" -ForegroundColor White
    } elseif ($status -eq "TERMINATED") {
        Write-Host "  VM: " -NoNewline -ForegroundColor White
        Write-Host "STOPPED ⏸️" -ForegroundColor Yellow
        Write-Host "  IP: $ip (reserved)" -ForegroundColor Gray
    } else {
        Write-Host "  VM: $status" -ForegroundColor Yellow
        Write-Host "  IP: $ip" -ForegroundColor White
    }
    
} catch {
    Write-Host "  VM: " -NoNewline -ForegroundColor White
    Write-Host "NOT FOUND ❌" -ForegroundColor Red
    Write-Host "  (Possibly destroyed - run .\spinup.ps1 to recreate)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💾 Persistent Disk Status:" -ForegroundColor Yellow
Write-Host ""

try {
    $diskInfo = gcloud compute disks describe sql-data-disk `
        --project=$ProjectId `
        --zone=$Zone `
        --format="json" 2>$null | ConvertFrom-Json
    
    Write-Host "  Disk: " -NoNewline -ForegroundColor White
    Write-Host "$($diskInfo.status) ✅" -ForegroundColor Green
    Write-Host "  Size: $($diskInfo.sizeGb) GB" -ForegroundColor White
    Write-Host "  Type: $($diskInfo.type.Split('/')[-1])" -ForegroundColor White
    
} catch {
    Write-Host "  Disk: " -NoNewline -ForegroundColor White
    Write-Host "NOT FOUND ❌" -ForegroundColor Red
}

# If VM is running, check Docker and SQL Server
if ($status -eq "RUNNING") {
    Write-Host ""
    Write-Host "🐳 Docker Status:" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $dockerPs = gcloud compute ssh $VmName `
            --project=$ProjectId `
            --zone=$Zone `
            --tunnel-through-iap `
            --command="sudo docker ps --filter name=mssql --format '{{.Names}}\t{{.Status}}'" 2>$null
        
        if ($dockerPs) {
            $parts = $dockerPs -split "`t"
            Write-Host "  Container: " -NoNewline -ForegroundColor White
            Write-Host "$($parts[0]) ✅" -ForegroundColor Green
            Write-Host "  Status: $($parts[1])" -ForegroundColor White
            
            # Check SQL Server connectivity
            Write-Host ""
            Write-Host "🗄️  SQL Server Status:" -ForegroundColor Yellow
            Write-Host ""
            
            # Note: This requires SQL_SA_PASSWORD env variable
            if ($env:SQL_SA_PASSWORD) {
                try {
                    $sqlCheck = gcloud compute ssh $VmName `
                        --project=$ProjectId `
                        --zone=$Zone `
                        --tunnel-through-iap `
                        --command="sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '$env:SQL_SA_PASSWORD' -C -Q 'SELECT @@VERSION' -h -1" 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  Connection: " -NoNewline -ForegroundColor White
                        Write-Host "OK ✅" -ForegroundColor Green
                        Write-Host "  Ready for queries" -ForegroundColor White
                    } else {
                        Write-Host "  Connection: " -NoNewline -ForegroundColor White
                        Write-Host "FAILED ❌" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "  Connection: " -NoNewline -ForegroundColor White
                    Write-Host "UNKNOWN ⚠️" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  Connection: " -NoNewline -ForegroundColor White
                Write-Host "SKIPPED" -ForegroundColor Gray
                Write-Host "  (Set `$env:SQL_SA_PASSWORD to test connection)" -ForegroundColor Gray
            }
            
        } else {
            Write-Host "  Container: " -NoNewline -ForegroundColor White
            Write-Host "NOT RUNNING ⚠️" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  ➡️  Deploy SQL Server via GitHub Actions:" -ForegroundColor Cyan
            Write-Host "     https://github.com/YOUR_REPO/actions" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Container: " -NoNewline -ForegroundColor White
        Write-Host "UNKNOWN ⚠️" -ForegroundColor Yellow
        Write-Host "  (Could not connect via SSH)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  STATUS CHECK COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Show helpful commands
if ($status -eq "RUNNING") {
    Write-Host "Quick Commands:" -ForegroundColor Cyan
    Write-Host "  Connect via SSH:" -ForegroundColor White
    Write-Host "    gcloud compute ssh $VmName --project=$ProjectId --zone=$Zone --tunnel-through-iap" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  View logs:" -ForegroundColor White
    Write-Host "    gcloud compute ssh $VmName --project=$ProjectId --zone=$Zone --tunnel-through-iap --command='sudo docker logs mssql'" -ForegroundColor Gray
    Write-Host ""
} elseif ($status -ne "RUNNING") {
    Write-Host "To start VM:" -ForegroundColor Yellow
    Write-Host "  .\spinup.ps1" -ForegroundColor White
    Write-Host ""
}
