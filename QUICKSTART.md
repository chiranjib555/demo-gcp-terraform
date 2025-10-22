# Quick Start Guide

## Prerequisites
- GCP account with billing enabled
- Terraform installed
- GitHub repository
- Your public IP address

## Step-by-Step Setup

### 1. Update Your IP Address

Edit `infra/terraform.tfvars`:
```hcl
admin_ip_cidr = "YOUR.PUBLIC.IP.HERE/32"  # Get from: curl ifconfig.me
```

### 2. Deploy Infrastructure

```bash
cd infra
terraform init
terraform apply
```

Save these outputs:
- `sqlvm_external_ip` - Your SQL Server IP
- `github_actions_sa_email` - Service account email

### 3. Extract Service Account Key

**PowerShell:**
```powershell
cd infra
terraform output -raw github_actions_sa_key | Out-File -Encoding utf8 sa-key-base64.txt
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content sa-key-base64.txt))) | Out-File sa-key.json
Get-Content sa-key.json
```

**Linux/Mac:**
```bash
terraform output -raw github_actions_sa_key | base64 -d > sa-key.json
cat sa-key.json
```

### 4. Add GitHub Secrets

Go to your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Name | Value | Example |
|------|-------|---------|
| `GCP_PROJECT_ID` | Your GCP project ID | `praxis-gantry-475007-k0` |
| `GCP_SA_KEY` | Contents of `sa-key.json` | `{"type":"service_account",...}` |
| `SQL_SA_PASSWORD` | SA password from terraform.tfvars | `ChangeMe_Strong#SA_2025!` |
| `SQL_CI_PASSWORD` | CI user password from terraform.tfvars | `ChangeMe_UseStrongPwd#2025!` |

### 5. Run First Deployment

1. Go to **Actions** tab in GitHub
2. Select **Deploy SQL Server to GCP**
3. Click **Run workflow**
4. Select `deploy`
5. Wait ~2 minutes

### 6. Verify Deployment

**From your local machine:**
```powershell
# PowerShell (install SqlServer module if needed)
Install-Module -Name SqlServer -Force

$connectionString = "Server=YOUR_VM_IP,1433;Database=DemoDB;User Id=ci_user;Password=YOUR_CI_PASSWORD;TrustServerCertificate=True;"
Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT @@VERSION"
```

**Via SSH:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --command \
  "sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YOUR_SA_PASSWORD' -C -Q 'SELECT name FROM sys.databases'"
```

---

## Daily Operations

### Tear Down VM (Stop Paying for Compute)
```bash
cd infra
terraform destroy -target=google_compute_instance.sqlvm -auto-approve
```
✅ Data is safe on persistent disk

### Spin Up VM (Resume Service)
```bash
terraform apply -auto-approve
```
Then run GitHub Actions workflow to deploy SQL Server container.

### Quick Restart SQL Server
Go to GitHub Actions → Run workflow → Select `restart`

### Stop SQL Server (Keep VM Running)
Go to GitHub Actions → Run workflow → Select `stop`

---

## Troubleshooting

### ❌ Terraform apply fails with "lifecycle prevent_destroy"

**Problem:** Trying to delete protected resources

**Solution:** 
```bash
# Remove lifecycle protection temporarily
terraform state rm google_compute_address.sqlvm_ip
terraform state rm google_compute_disk.sql_data

# Then destroy
terraform destroy
```

### ❌ GitHub Actions: "Permission denied (publickey)"

**Problem:** Service account doesn't have IAP permissions

**Solution:**
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.osLogin"
```

### ❌ Can't connect to SQL Server from local machine

**Problem:** Firewall or wrong IP

**Check your current IP:**
```bash
curl ifconfig.me
```

**Update terraform.tfvars and reapply:**
```bash
cd infra
terraform apply
```

### ❌ SQL Server container keeps restarting

**Check logs:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo docker logs mssql
```

**Common issues:**
- Password doesn't meet complexity requirements (1 uppercase, 1 lowercase, 1 digit, 1 special char, min 8 chars)
- Disk permissions wrong: `sudo chown -R 10001:10001 /mnt/sqldata`
- Not enough memory (need 2GB minimum)

---

## Cost Estimate

| Scenario | Monthly Cost (us-central1) |
|----------|----------------------------|
| **24/7 uptime** | ~$73/month |
| **8 hours/day (M-F)** | ~$37/month |
| **VM destroyed, disk kept** | ~$24/month (disk + IP) |

**Cost breakdown:**
- VM (e2-standard-2): $0.067/hour
- Persistent SSD (100GB): $17/month
- Static IP (allocated): $7.20/month

---

## Next Steps

✅ **Test the tear down/spin up cycle:**
```bash
# Save some test data
Invoke-Sqlcmd -ConnectionString "Server=IP,1433;..." -Query "CREATE TABLE Test (Id INT); INSERT INTO Test VALUES (1);"

# Tear down
terraform destroy -target=google_compute_instance.sqlvm -auto-approve

# Spin up
terraform apply -auto-approve

# Deploy SQL Server via GitHub Actions

# Verify data persisted
Invoke-Sqlcmd -ConnectionString "Server=IP,1433;..." -Query "SELECT * FROM Test"
```

✅ **Set up automated deployments** (optional):
- Add schedule trigger to GitHub Actions for weekday mornings
- Combine with Cloud Scheduler to start/stop VM

✅ **Implement backups:**
- Add backup step to GitHub Actions workflow
- Store backups in Cloud Storage

---

**Need help?** Check the main [README.md](README.md) for detailed documentation.
