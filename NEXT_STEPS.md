# 🎉 Setup Complete! Next Steps

## What You Have Now

✅ **Persistent Infrastructure**
- Static IP that never changes
- 100GB SSD disk for SQL Server data
- Data survives VM rebuilds

✅ **Automated Deployment**
- GitHub Actions workflow for SQL Server container
- IAP tunnel for secure access (no public SSH)
- Idempotent database initialization

✅ **Cost Optimization**
- Tear down VM when not in use
- Persistent disk keeps your data safe
- Save up to $36/month

✅ **Helper Scripts**
- `teardown.ps1` - Destroy VM (keep data)
- `spinup.ps1` - Recreate VM
- `check-status.ps1` - Check infrastructure status
- `update-ip.ps1` - Update firewall for new IP

---

## Quick Start: First Deployment

### 1. Review Configuration

Check `infra/terraform.tfvars`:
```hcl
admin_ip_cidr      = "YOUR_IP/32"        # Your current IP
sql_sa_password    = "CHANGE_ME"         # Strong password!
sql_admin_password = "CHANGE_ME"         # Strong password!
```

### 2. Apply Infrastructure

```powershell
cd infra
terraform init
terraform apply
```

**Save these outputs:**
- `sqlvm_external_ip` → Your SQL Server IP
- `github_actions_sa_key` → For GitHub Secrets

### 3. Extract Service Account Key

```powershell
cd infra
terraform output -raw github_actions_sa_key | Out-File -Encoding utf8 sa-key-base64.txt
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content sa-key-base64.txt))) | Out-File sa-key.json
```

### 4. Configure GitHub Secrets

Go to: **Settings → Secrets and variables → Actions**

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `GCP_PROJECT_ID` | `praxis-gantry-475007-k0` |
| `GCP_SA_KEY` | Contents of `sa-key.json` |
| `SQL_SA_PASSWORD` | From `terraform.tfvars` |
| `SQL_CI_PASSWORD` | From `terraform.tfvars` |

### 5. Deploy SQL Server

**Option A: GitHub Actions UI**
1. Go to **Actions** tab
2. Select **Deploy SQL Server to GCP**
3. Click **Run workflow**
4. Wait ~2 minutes

**Option B: Push to Git**
```bash
git add .
git commit -m "Initial infrastructure setup"
git push origin main
```

### 6. Verify Deployment

```powershell
# Check status
.\check-status.ps1

# Test SQL connection (PowerShell)
$connectionString = "Server=YOUR_VM_IP,1433;Database=DemoDB;User Id=ci_user;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT @@VERSION"
```

---

## Daily Operations

### 🌙 Tear Down for the Night
```powershell
.\teardown.ps1
```
**Saves:** ~$1.50/day  
**Data:** Safe on persistent disk  
**IP:** Stays the same

### ☀️ Spin Up in the Morning
```powershell
.\spinup.ps1
```
Then run GitHub Actions workflow to deploy SQL Server.

### 📊 Check Status Anytime
```powershell
.\check-status.ps1
```

### 🌐 IP Address Changed?
```powershell
.\update-ip.ps1
```

---

## Testing the "Tear Down / Spin Up" Cycle

### Test Data Persistence

1. **Create test data:**
```powershell
$connString = "Server=YOUR_IP,1433;Database=DemoDB;User Id=ci_user;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
Invoke-Sqlcmd -ConnectionString $connString -Query @"
CREATE TABLE TestPersistence (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    Message NVARCHAR(100)
);
INSERT INTO TestPersistence (Message) VALUES ('Data before teardown');
SELECT * FROM TestPersistence;
"@
```

2. **Tear down VM:**
```powershell
.\teardown.ps1
```

3. **Spin up VM:**
```powershell
.\spinup.ps1
```

4. **Deploy SQL Server via GitHub Actions**

5. **Verify data persisted:**
```powershell
Invoke-Sqlcmd -ConnectionString $connString -Query "SELECT * FROM TestPersistence"
```

You should see your data intact! 🎉

---

## Deployment Modes

### IAP Mode (Default - Recommended)
- ✅ Secure (no public SSH)
- ✅ Uses Google's IAP proxy
- ✅ Better for production
- Current workflow: `.github/workflows/deploy-sql.yml`

### Simple Mode (Alternative)
- ✅ Easier to debug
- ✅ Direct SSH connection
- ⚠️ Requires SSH key management
- See: `SIMPLE_MODE.md`

---

## Cost Optimization Strategies

### Strategy 1: Work Hours Only (8 AM - 6 PM, M-F)
```
Monthly cost: ~$37
Savings: $20/month (35%)
```

**Automation:**
```powershell
# Schedule with Task Scheduler
# Morning (8 AM):
.\spinup.ps1
# Then trigger GitHub Actions via API

# Evening (6 PM):
.\teardown.ps1
```

### Strategy 2: On-Demand Only
```
Monthly cost: ~$24 (just disk + IP)
Savings: $33/month (58%)
```

**Usage:**
- Spin up when you need to work
- Tear down when done
- Data always safe

---

## Troubleshooting

### ❌ terraform apply fails

**Error:** "lifecycle prevent_destroy"  
**Solution:** You're trying to delete protected resources
```powershell
# Remove protection temporarily
cd infra
terraform state rm google_compute_address.sqlvm_ip
terraform state rm google_compute_disk.sql_data
terraform destroy
```

### ❌ GitHub Actions: Permission denied

**Solution:** Grant IAP permissions
```bash
gcloud projects add-iam-policy-binding praxis-gantry-475007-k0 \
  --member="serviceAccount:github-actions-deployer@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

### ❌ Can't connect to SQL Server

**Check firewall:**
```powershell
.\update-ip.ps1
```

**Check if SQL Server is running:**
```powershell
.\check-status.ps1
```

### ❌ Startup script failed

**View logs:**
```bash
gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a
```

**Common issue:** Line endings
```powershell
# Fix CRLF → LF
(Get-Content .\infra\scripts\vm-prep.sh.tftpl -Raw) -replace "`r`n", "`n" | Set-Content -NoNewline .\infra\scripts\vm-prep.sh.tftpl
```

---

## Maintenance

### Update SQL Server Version
Edit `.github/workflows/deploy-sql.yml`:
```yaml
env:
  SQL_VERSION: "2022-latest"  # or "2019-latest"
```

### Increase Disk Size
Edit `infra/terraform.tfvars`:
```hcl
disk_size_gb = 200  # From 100GB
```
Then: `terraform apply`

### Backup Database
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --command \
  "sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Password' -C \
   -Q \"BACKUP DATABASE [DemoDB] TO DISK = '/var/opt/mssql/data/DemoDB.bak'\""
```

Download backup:
```bash
gcloud compute scp sql-linux-vm:/mnt/sqldata/data/DemoDB.bak ./DemoDB.bak --zone=us-central1-a --tunnel-through-iap
```

---

## Documentation

| File | Purpose |
|------|---------|
| `README.md` | Complete documentation |
| `QUICKSTART.md` | Step-by-step setup guide |
| `MIGRATION.md` | Migration from old setup |
| `SIMPLE_MODE.md` | Alternative deployment without IAP |
| `SCRIPTS.md` | Helper scripts documentation |
| `NEXT_STEPS.md` | This file! |

---

## Advanced: Scheduled Automation

### Windows Task Scheduler

**Auto tear down at 6 PM:**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\teardown.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 6PM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GCP SQL Teardown"
```

**Auto spin up at 8 AM:**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\spinup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 8AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GCP SQL Spinup"
```

### GitHub Actions: Scheduled Deployment

Add to `.github/workflows/deploy-sql.yml`:
```yaml
on:
  schedule:
    - cron: '0 8 * * 1-5'  # 8 AM weekdays
  workflow_dispatch:
```

---

## Security Checklist

- [ ] Changed default passwords in `terraform.tfvars`
- [ ] Stored passwords securely in GitHub Secrets
- [ ] Updated `admin_ip_cidr` with your current IP
- [ ] Enabled OS Login for VM
- [ ] Using IAP tunnel (not direct SSH)
- [ ] Service account has minimal permissions
- [ ] `.tfvars` files in `.gitignore`
- [ ] Service account key not committed to git

---

## Support & Resources

**Official Documentation:**
- [GCP IAP Documentation](https://cloud.google.com/iap/docs)
- [SQL Server on Linux](https://learn.microsoft.com/en-us/sql/linux/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

**Project Files:**
- Infrastructure: `infra/`
- Scripts: `infra/scripts/`
- Workflows: `.github/workflows/`
- Helper scripts: Root directory (`*.ps1`)

---

## What's Next?

### Immediate Tasks
1. ✅ Complete initial deployment
2. ✅ Test tear down/spin up cycle
3. ✅ Verify data persistence
4. ✅ Set up daily automation (optional)

### Future Enhancements
- 🔄 Automated backups to Cloud Storage
- 🔄 Monitoring and alerting
- 🔄 Blue/green deployments
- 🔄 Database migration scripts
- 🔄 Performance tuning
- 🔄 Disaster recovery plan

---

## Success Criteria

You're all set when:
- ✅ VM can be destroyed and recreated
- ✅ Static IP never changes
- ✅ Data persists across rebuilds
- ✅ GitHub Actions deploys SQL Server automatically
- ✅ You can connect from your local machine
- ✅ Costs are reduced by 35-58%

---

**🎉 Congratulations!** You now have a production-ready, cost-optimized, tear-down/spin-up infrastructure!

Need help? Check the docs or create an issue in your repository.

**Happy deploying!** 🚀
