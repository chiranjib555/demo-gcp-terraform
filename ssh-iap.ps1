# SSH to VM via IAP Tunnel (works from any IP!)
# No need to update firewall when IP changes

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SSH via IAP Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connecting to sql-linux-vm via IAP..." -ForegroundColor Yellow
Write-Host "(This works from ANY IP address!)" -ForegroundColor Green
Write-Host ""

gcloud compute ssh sql-linux-vm `
    --zone=us-central1-a `
    --tunnel-through-iap `
    --project=praxis-gantry-475007-k0

Write-Host ""
Write-Host "Disconnected." -ForegroundColor Yellow
