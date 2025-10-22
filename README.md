# GCP SQL Server Infrastructure - Tear Down / Spin Up on Demand

This infrastructure uses a **persistent disk** and **static IP** so your SQL Server data and connection strings remain stable across VM rebuilds. GitHub Actions deploys the SQL Server container automatically.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions (GitHub-hosted runners)                     │
│  ├─ Authenticates via service account                       │
│  ├─ SSH via IAP tunnel (no public SSH exposure)             │
│  └─ Deploys SQL Server container + runs init scripts        │
└──────────────────┬──────────────────────────────────────────┘
                   │ IAP Tunnel (35.235.240.0/20)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  GCP Compute VM (Debian 11)                                 │
│  ├─ Static IP: 34.57.37.222 (prevent_destroy = true)        │
│  ├─ Docker installed via startup script                     │
│  ├─ Persistent Disk: /mnt/sqldata (100GB SSD)               │
│  │  └─ Survives VM destroy/recreate                         │
│  └─ SQL Server 2022 container (deployed via GitHub Actions) │
│     ├─ Data: /var/opt/mssql/data → /mnt/sqldata/data        │
│     ├─ Logs: /var/opt/mssql/log → /mnt/sqldata/log          │
│     └─ Port: 1433 (accessible from your IP)                 │
└─────────────────────────────────────────────────────────────┘
```

### What Survives Rebuilds?

✅ **Static IP** (`google_compute_address.sqlvm_ip`) - `prevent_destroy = true`  
✅ **Persistent disk** (`google_compute_disk.sql_data`) - `prevent_destroy = true`  
✅ **All SQL Server databases and data** - stored on persistent disk  
❌ **VM instance** - destroyed and recreated on demand  
❌ **Docker containers** - redeployed by GitHub Actions

---

## Initial Setup

### 1. Enable Required APIs

```bash
gcloud services enable compute.googleapis.com \
  iamcredentials.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iap.googleapis.com
```

### 2. Deploy Infrastructure with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

**Important outputs:**
- `sqlvm_external_ip` - Your stable SQL Server IP address
- `github_actions_sa_email` - Service account for GitHub Actions
- `github_actions_sa_key` - Service account private key (base64 JSON)

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `GCP_PROJECT_ID` | `praxis-gantry-475007-k0` | Your GCP project ID |
| `GCP_SA_KEY` | `<base64-json>` | `terraform output -raw github_actions_sa_key \| base64 -d` |
| `SQL_SA_PASSWORD` | `ChangeMe_Strong#SA_2025!` | Your SQL SA password (from `terraform.tfvars`) |
| `SQL_CI_PASSWORD` | `ChangeMe_UseStrongPwd#2025!` | Your CI user password (from `terraform.tfvars`) |

**To extract the service account key:**
```bash
# PowerShell (Windows)
terraform output -raw github_actions_sa_key | Out-File -Encoding utf8 sa-key-base64.txt
# Decode and view
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content sa-key-base64.txt))) | Out-File sa-key.json
# Copy contents of sa-key.json to GCP_SA_KEY secret
```

### 4. Enable IAP for your service account

```bash
gcloud projects add-iam-policy-binding praxis-gantry-475007-k0 \
  --member="serviceAccount:github-actions-deployer@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

---

## Usage

### Deploy SQL Server Container

**Via GitHub Actions UI:**
1. Go to `Actions` tab in GitHub
2. Select `Deploy SQL Server to GCP` workflow
3. Click `Run workflow`
4. Choose action: `deploy` (default), `restart`, or `stop`

**Via Git Push:**
- Push changes to `main` branch
- Workflow automatically deploys if `init-database.sql` or workflow file changes

### Tear Down VM (Save Costs)

```bash
cd infra
terraform destroy -target=google_compute_instance.sqlvm
```

**What happens:**
- ✅ VM is destroyed (no more compute charges)
- ✅ Static IP remains allocated (small charge ~$0.01/hour)
- ✅ Persistent disk remains (charged for storage ~$0.17/GB/month)
- ✅ All your SQL Server data is safe

### Spin Up VM (Restore Service)

```bash
cd infra
terraform apply
```

**What happens:**
1. VM recreates with **same static IP**
2. Persistent disk **automatically reattaches**
3. Startup script runs (installs Docker, mounts disk)
4. GitHub Actions deploys SQL Server container
5. Database data is **exactly where you left it**

---

## Deployment Modes

### Mode 1: IAP Tunnel (Recommended for Production)

**How it works:**
- GitHub Actions connects via Google's IAP proxy
- No public SSH exposure (port 22 only open to IAP range)
- Requires `roles/iap.tunnelResourceAccessor` permission

**Current setup:** ✅ Enabled by default in `.github/workflows/deploy-sql.yml`

**Firewall rule:**
```hcl
resource "google_compute_firewall" "iap_ssh" {
  source_ranges = ["35.235.240.0/20"]  # Google IAP range
  allow { protocol = "tcp"; ports = ["22"] }
}
```

### Mode 2: Public SSH (Simple, Dev-Friendly)

**How it works:**
- GitHub Actions SSH directly to VM's public IP
- Requires firewall rule to allow GitHub Actions IPs

**To switch to public SSH:**

1. Update `.github/workflows/deploy-sql.yml`:
   ```yaml
   # Change this:
   gcloud compute ssh $VM_NAME --tunnel-through-iap
   
   # To this:
   ssh -o StrictHostKeyChecking=no <user>@$VM_EXTERNAL_IP
   ```

2. Add GitHub Actions IP ranges to firewall (or open to `0.0.0.0/0` for simplicity)

---

## Connection Details

**SQL Server Connection String:**
```
Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=<SQL_CI_PASSWORD>;TrustServerCertificate=True;
```

**Direct SQL Query (PowerShell):**
```powershell
$connectionString = "Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=ChangeMe_UseStrongPwd#2025!;TrustServerCertificate=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = "SELECT @@VERSION"
$result = $command.ExecuteScalar()
Write-Host $result
$connection.Close()
```

---

## Files Overview

### Terraform Files

| File | Purpose |
|------|---------|
| `compute.sql-linux.tf` | VM definition with persistent disk attachment |
| `github-actions-sa.tf` | Service account for GitHub Actions (IAP + SSH) |
| `firewall.tf` | Firewall rules (SSH from your IP, IAP, SQL port) |
| `vpc.tf` | VPC network and subnet |
| `variables.tf` | Input variables (disk size, passwords, etc.) |
| `outputs.tf` | Important values (IP, disk name, SA email) |

### Scripts

| File | Purpose |
|------|---------|
| `scripts/vm-prep.sh.tftpl` | Startup script (Docker install, mount disk) |
| `scripts/init-database.sql` | SQL init script (creates DB, users, tables) |

### GitHub Actions

| File | Purpose |
|------|---------|
| `.github/workflows/deploy-sql.yml` | Deploy SQL Server container via IAP |

---

## Troubleshooting

### Startup Script Failed

**Check logs:**
```bash
gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a
```

**Common issue:** Line endings (CRLF vs LF)
```powershell
# Fix in PowerShell
(Get-Content .\infra\scripts\vm-prep.sh.tftpl -Raw) -replace "`r`n", "`n" | Set-Content -NoNewline .\infra\scripts\vm-prep.sh.tftpl
```

### GitHub Actions Can't SSH

**Check IAP permissions:**
```bash
gcloud projects get-iam-policy praxis-gantry-475007-k0 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deployer*"
```

**Required roles:**
- `roles/compute.osLogin`
- `roles/iap.tunnelResourceAccessor`
- `roles/compute.viewer`

### SQL Server Won't Start

**Check container logs:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --command "sudo docker logs mssql"
```

**Common issues:**
- Password doesn't meet complexity requirements
- Disk permissions (should be owned by UID 10001)
- Not enough memory (min 2GB recommended)

### Can't Connect to SQL Server

**Test from VM:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourPassword' -C -Q "SELECT @@VERSION"
```

**Check firewall:**
```bash
gcloud compute firewall-rules list --filter="name:allow-sql-1433-admin"
```

**Verify your IP is allowed:**
```bash
curl -s ifconfig.me
# Should match admin_ip_cidr in terraform.tfvars
```

---

## Cost Optimization

### Estimated Monthly Costs (us-central1)

| Resource | Usage | Cost |
|----------|-------|------|
| **VM (e2-standard-2)** | 730 hours/month | ~$49/month |
| **VM (e2-standard-2)** | 8 hours/day (tear down) | ~$13/month |
| **Persistent Disk (SSD)** | 100GB | ~$17/month |
| **Static IP (allocated)** | Always | ~$7/month |
| **Static IP (in-use)** | Free when VM running | $0 |

**Tear Down Strategy:**
- Destroy VM when not in use: **Save up to $36/month**
- Persistent disk always charged: **$17/month fixed**
- Static IP small fee: **~$7/month** (ensures stable IP)

**Spin up for work hours:**
```bash
# Morning
terraform apply -auto-approve

# Evening
terraform destroy -target=google_compute_instance.sqlvm -auto-approve
```

---

## Maintenance

### Update SQL Server Version

Edit `.github/workflows/deploy-sql.yml`:
```yaml
env:
  SQL_VERSION: "2022-latest"  # or "2019-latest", "2022-CU10-ubuntu-22.04"
```

### Increase Disk Size

```bash
# Update terraform.tfvars
disk_size_gb = 200

# Apply changes (no data loss!)
terraform apply
```

**Resize filesystem on VM:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo resize2fs /dev/disk/by-id/google-sql-data
```

### Backup Database

**Using GitHub Actions:**
```bash
gcloud compute ssh sql-linux-vm --tunnel-through-iap --command \
  "sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Password' -C \
   -Q \"BACKUP DATABASE [DemoDB] TO DISK = '/var/opt/mssql/data/DemoDB.bak'\""
```

**Download backup:**
```bash
gcloud compute scp sql-linux-vm:/mnt/sqldata/data/DemoDB.bak ./DemoDB.bak --tunnel-through-iap
```

---

## Next Steps

1. ✅ **Test tear down / spin up cycle**
   ```bash
   terraform destroy -target=google_compute_instance.sqlvm
   terraform apply
   # Run GitHub Actions workflow to deploy SQL Server
   ```

2. ✅ **Verify data persistence**
   - Insert test data
   - Tear down VM
   - Spin up VM
   - Verify data still exists

3. 🔄 **Set up scheduled deployments** (optional)
   - Add `schedule` trigger to workflow for auto-deploy
   - Example: Deploy every weekday at 8 AM

4. 🔐 **Rotate passwords** (recommended quarterly)
   - Update GitHub Secrets
   - Update `terraform.tfvars`
   - Run GitHub Actions workflow

---

## Security Best Practices

- ✅ Use IAP tunnel instead of public SSH
- ✅ Service account with minimal permissions
- ✅ SQL passwords stored in GitHub Secrets (encrypted)
- ✅ Firewall rules restrict SQL port to your IP only
- ✅ Enable OS Login for better audit logging
- 🔄 Rotate service account keys every 90 days
- 🔄 Enable Cloud Audit Logs for compliance
- 🔄 Use Workload Identity Federation for GitHub Actions (eliminates key management)

---

## Support

**Logs:**
- VM startup: `gcloud compute instances get-serial-port-output sql-linux-vm`
- Docker: `sudo docker logs mssql`
- SQL Server: `sudo docker exec mssql cat /var/opt/mssql/log/errorlog`

**Documentation:**
- [GCP IAP for TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)
- [SQL Server on Linux](https://learn.microsoft.com/en-us/sql/linux/)
- [GitHub Actions with GCP](https://github.com/google-github-actions/auth)

---

**Version:** 1.0.0  
**Last Updated:** {{ date }}  
**Project:** demo-gcp-terraform
