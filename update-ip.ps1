$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UPDATE FIREWALL FOR NEW IP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current public IP
Write-Host "Detecting your current public IP..." -ForegroundColor Yellow

try {
    $currentIp = (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing -TimeoutSec 10).Content.Trim()
    Write-Host ""
    Write-Host "Your current IP: " -NoNewline -ForegroundColor White
    Write-Host "$currentIp" -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Host "❌ Could not detect IP address automatically." -ForegroundColor Red
    Write-Host ""
    $currentIp = Read-Host "Enter your public IP address"
    if (-not $currentIp) {
        Write-Host "No IP provided. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Update terraform.tfvars
$tfvarsPath = "$PSScriptRoot\infra\terraform.tfvars"

if (-not (Test-Path $tfvarsPath)) {
    Write-Host "❌ terraform.tfvars not found at: $tfvarsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Updating terraform.tfvars..." -ForegroundColor Yellow

# Read current content
$content = Get-Content $tfvarsPath -Raw

# Replace admin_ip_cidr value
$newContent = $content -replace 'admin_ip_cidr\s*=\s*"[^"]*"', "admin_ip_cidr = `"$currentIp/32`""

# Save updated content
$newContent | Set-Content -Path $tfvarsPath -NoNewline

Write-Host "✅ Updated terraform.tfvars" -ForegroundColor Green
Write-Host ""

# Ask to apply changes
Write-Host "Apply firewall changes now?" -ForegroundColor Yellow
$apply = Read-Host "(yes/no)"

if ($apply -eq "yes") {
    Write-Host ""
    Write-Host "Applying Terraform changes..." -ForegroundColor Yellow
    
    Set-Location -Path "$PSScriptRoot\infra"
    
    terraform apply -auto-approve
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ FIREWALL UPDATED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now connect from: $currentIp" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test connection:" -ForegroundColor Yellow
    Write-Host "  .\check-status.ps1" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "⚠️  Changes saved but not applied." -ForegroundColor Yellow
    Write-Host "Run 'terraform apply' in the infra/ directory to apply changes." -ForegroundColor White
    Write-Host ""
}
