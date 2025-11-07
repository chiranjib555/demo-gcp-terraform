# SQL Server Connection via SSH Port Forwarding (more reliable than IAP tunnel on Windows)
# This uses SSH to forward localhost:51433 to VM's localhost:1433

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SQL Server SSH Port Forward Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creating SSH tunnel with port forwarding..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Connect with:" -ForegroundColor Green
Write-Host "  Server:   localhost,51433" -ForegroundColor White
Write-Host "  Database: DemoDB" -ForegroundColor White
Write-Host "  User:     ci_user" -ForegroundColor White
Write-Host "  Password: ChangeMe_UseStrongPwd#2025!" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Yellow
Write-Host ""

# Use gcloud compute ssh with SSH options for port forwarding
# -N = Don't execute remote command (just forward ports)
# -L = Local port forwarding (local:remote)
gcloud compute ssh sql-linux-vm `
    --zone=us-central1-a `
    --tunnel-through-iap `
    --project=praxis-gantry-475007-k0 `
    --ssh-flag="-N" `
    --ssh-flag="-L" `
    --ssh-flag="51433:localhost:1433"
