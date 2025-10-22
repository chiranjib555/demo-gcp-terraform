$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GCP SQL VM - TEAR DOWN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will destroy the VM but keep your data safe." -ForegroundColor Yellow
Write-Host "Persistent disk and static IP will be preserved." -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Destroying VM instance..." -ForegroundColor Yellow

Set-Location -Path "$PSScriptRoot\infra"

# Destroy only the VM instance
terraform destroy -target=google_compute_instance.sqlvm -auto-approve

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ TEAR DOWN COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "💾 Your data is safe on persistent disk" -ForegroundColor Cyan
Write-Host "🌐 Static IP is preserved" -ForegroundColor Cyan
Write-Host "💰 Saving ~`$1.50/day on compute costs" -ForegroundColor Green
Write-Host ""
Write-Host "To restore service, run:" -ForegroundColor Yellow
Write-Host "  .\spinup.ps1" -ForegroundColor White
Write-Host ""
