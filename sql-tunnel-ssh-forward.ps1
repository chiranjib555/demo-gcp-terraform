# SQL Server Tunnel via SSH Port Forwarding + IAP
# This is more reliable than direct IAP tunnel for SQL Server
# Uses SSH to forward port 1433 to your local machine

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SQL Server Tunnel (SSH Forward)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creating SSH tunnel with port forwarding..." -ForegroundColor Yellow
Write-Host "Local Port: 51433 -> VM Port: 1433" -ForegroundColor Magenta
Write-Host ""
Write-Host "Connect SSMS with:" -ForegroundColor Green
Write-Host "  Server:   localhost,51433" -ForegroundColor White
Write-Host "  Database: DemoDB" -ForegroundColor White
Write-Host "  Login:    ci_user" -ForegroundColor White
Write-Host "  Password: ChangeMe_UseStrongPwd#2025!" -ForegroundColor White
Write-Host ""
Write-Host "Or for SA access:" -ForegroundColor Green
Write-Host "  Login:    sa" -ForegroundColor White
Write-Host "  Password: YourSecureP@ssw0rd!123" -ForegroundColor White
Write-Host ""
Write-Host "Keep this window open while using SSMS!" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Yellow
Write-Host ""

# First, we need to generate the IAP proxy command
Write-Host "Setting up IAP proxy command..." -ForegroundColor Gray

# Get the IAP proxy command from gcloud
$proxyCommand = "gcloud compute start-iap-tunnel sql-linux-vm 22 --listen-on-stdin --zone=us-central1-a --project=praxis-gantry-475007-k0"

# Use plink with the IAP proxy to forward port 1433
# -N = No shell (just forward ports)
# -L = Local port forwarding
# -ssh = Force SSH protocol
# -batch = Non-interactive mode
Write-Host "Starting SSH tunnel with port forwarding..." -ForegroundColor Gray
Write-Host ""

& "C:\Program Files\PuTTY\plink.exe" `
    -N `
    -L 51433:localhost:1433 `
    -ssh `
    -batch `
    -agent `
    -ProxyCommand $proxyCommand `
    chiranjib555@sql-linux-vm

Write-Host ""
Write-Host "Tunnel closed." -ForegroundColor Yellow
