$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GCP SQL VM - SPIN UP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Recreating VM with persistent disk and static IP..." -ForegroundColor Yellow
Write-Host ""

Set-Location -Path "$PSScriptRoot\infra"

# Apply Terraform
terraform apply -auto-approve

Write-Host ""
Write-Host "Getting VM details..." -ForegroundColor Yellow

try {
    $VM_IP = terraform output -raw sqlvm_external_ip
    $DISK_NAME = terraform output -raw persistent_disk_name
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ SPIN UP COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "VM Details:" -ForegroundColor Cyan
    Write-Host "  🌐 IP Address: $VM_IP" -ForegroundColor White
    Write-Host "  💾 Disk: $DISK_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host "⏳ Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Wait ~2 minutes for startup script to complete" -ForegroundColor White
    Write-Host "  2. Deploy SQL Server container via GitHub Actions" -ForegroundColor White
    Write-Host ""
    Write-Host "To deploy SQL Server:" -ForegroundColor Cyan
    Write-Host "  Option A: GitHub Actions UI" -ForegroundColor White
    Write-Host "    → Go to: https://github.com/YOUR_REPO/actions" -ForegroundColor Gray
    Write-Host "    → Run workflow: 'Deploy SQL Server to GCP'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Option B: Via gcloud (after GitHub Actions setup)" -ForegroundColor White
    Write-Host "    → gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To check status:" -ForegroundColor Cyan
    Write-Host "  .\check-status.ps1" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "⚠️  Could not retrieve outputs. Run 'terraform output' manually." -ForegroundColor Yellow
}
