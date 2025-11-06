# Connect to SQL Server via IAP Tunnel (works from any IP!)
# Creates a local tunnel: localhost:1433 -> VM:1433

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SQL Server IAP Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creating IAP tunnel to SQL Server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Connect with:" -ForegroundColor Green
Write-Host "  Server:   localhost,1433" -ForegroundColor White
Write-Host "  Database: DemoDB" -ForegroundColor White
Write-Host "  User:     ci_user" -ForegroundColor White
Write-Host "  Password: ChangeMe_UseStrongPwd#2025!" -ForegroundColor White
Write-Host ""
Write-Host "Connection String:" -ForegroundColor Green
Write-Host "  Server=localhost,1433;Database=DemoDB;User Id=ci_user;Password=ChangeMe_UseStrongPwd#2025!;TrustServerCertificate=True;" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Yellow
Write-Host ""

# Create IAP tunnel: localhost:1433 -> VM:1433
gcloud compute start-iap-tunnel sql-linux-vm 1433 `
    --local-host-port=localhost:1433 `
    --zone=us-central1-a `
    --project=praxis-gantry-475007-k0
