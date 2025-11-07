# Temporarily enable direct SQL Server access
# Use this if IAP tunnel has issues on Windows

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Enable Public SQL Access" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will allow direct connection to SQL Server from your IP" -ForegroundColor Magenta
Write-Host ""

# Get current public IP
Write-Host "Detecting your public IP..." -ForegroundColor Gray
$publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
Write-Host "Your IP: $publicIP" -ForegroundColor Cyan
Write-Host ""

# Uncomment the firewall rule in firewall.tf
Write-Host "Creating temporary firewall rule..." -ForegroundColor Yellow

gcloud compute firewall-rules create allow-sql-temp `
    --network=demo-vpc `
    --allow=tcp:1433 `
    --source-ranges="$publicIP/32" `
    --description="Temporary SQL access for troubleshooting" `
    --project=praxis-gantry-475007-k0

Write-Host ""
Write-Host "[SUCCESS] SQL Server is now accessible!" -ForegroundColor Green
Write-Host ""
Write-Host "Connect SSMS with:" -ForegroundColor Green
Write-Host "  Server:   34.57.37.222,1433" -ForegroundColor White
Write-Host "  Login:    ci_user" -ForegroundColor White
Write-Host "  Password: ChangeMe_UseStrongPwd#2025!" -ForegroundColor White
Write-Host ""
Write-Host "[WARNING] Remember to disable this when done:" -ForegroundColor Yellow
Write-Host "  .\disable-sql-public-access.ps1" -ForegroundColor Cyan
Write-Host ""
