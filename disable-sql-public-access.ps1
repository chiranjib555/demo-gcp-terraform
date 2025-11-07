# Disable temporary public SQL Server access

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Disable Public SQL Access" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Removing temporary firewall rule..." -ForegroundColor Gray

gcloud compute firewall-rules delete allow-sql-temp `
    --project=praxis-gantry-475007-k0 `
    --quiet

Write-Host ""
Write-Host "[SUCCESS] Public SQL access disabled" -ForegroundColor Green
Write-Host "  SQL Server is now IAP-only again" -ForegroundColor Cyan
Write-Host ""
