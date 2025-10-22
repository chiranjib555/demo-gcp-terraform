# Migration Summary: On-Demand Infrastructure

## What Changed?

### ✅ New Approach: "Tear Down / Spin Up on Demand"

**Before:**
- VM runs 24/7 (~$49/month)
- SQL Server deployed via startup script
- Line ending issues with startup scripts
- No easy way to save costs

**After:**
- VM can be destroyed/recreated on demand
- SQL Server data persists on separate disk
- Static IP never changes
- GitHub Actions deploys SQL Server container
- Save ~$36/month by tearing down when not in use

---

## Infrastructure Changes

### 1. Persistent Disk (NEW)
**File:** `infra/compute.sql-linux.tf`

```hcl
resource "google_compute_disk" "sql_data" {
  name = "sql-data-disk"
  type = "pd-ssd"
  size = 100
  
  lifecycle {
    prevent_destroy = true  # 🔒 Data is protected!
  }
}
```

**Benefits:**
- 100GB SSD for database files
- Survives VM deletion
- Auto-reattaches on VM recreate
- ~$17/month fixed cost

### 2. Static IP Protection
**File:** `infra/compute.sql-linux.tf`

```hcl
resource "google_compute_address" "sqlvm_ip" {
  name   = "sqlvm-ip"
  region = var.region
  
  lifecycle {
    prevent_destroy = true  # 🔒 IP is protected!
  }
}
```

**Benefits:**
- Connection strings never change
- No DNS updates needed
- ~$7/month when VM is down

### 3. Minimal Startup Script
**File:** `infra/scripts/vm-prep.sh.tftpl` (NEW)

**What it does:**
- Install Docker
- Format and mount persistent disk
- Set proper permissions
- **Does NOT deploy SQL Server** (that's GitHub Actions' job)

**Benefits:**
- Fast VM startup (~2 minutes)
- No line ending issues (pure bash, no templating of secrets)
- Idempotent (can run multiple times)

### 4. GitHub Actions Deployment
**File:** `.github/workflows/deploy-sql.yml` (NEW)

**What it does:**
- SSH to VM via IAP tunnel (secure!)
- Deploy SQL Server container
- Run database initialization script
- Verify deployment

**Triggers:**
- Manual (via Actions UI)
- Push to `main` (when SQL scripts change)

### 5. IAP Firewall Rule
**File:** `infra/firewall.tf`

```hcl
resource "google_compute_firewall" "iap_ssh" {
  name          = "allow-iap-ssh"
  source_ranges = ["35.235.240.0/20"]  # Google IAP range
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
```

**Benefits:**
- No public SSH exposure
- GitHub Actions can connect securely
- Better audit trail

### 6. Service Account for GitHub Actions
**File:** `infra/github-actions-sa.tf` (NEW)

**Roles granted:**
- `roles/compute.osLogin` - SSH via OS Login
- `roles/iap.tunnelResourceAccessor` - Connect via IAP
- `roles/compute.viewer` - View VM details

**Benefits:**
- Principle of least privilege
- Service account key stored in GitHub Secrets
- Easy to rotate credentials

---

## New Files Created

| File | Purpose |
|------|---------|
| `infra/scripts/vm-prep.sh.tftpl` | Minimal startup script (Docker + disk mount) |
| `infra/scripts/init-database.sql` | Idempotent SQL initialization |
| `infra/github-actions-sa.tf` | Service account for CI/CD |
| `.github/workflows/deploy-sql.yml` | Automated SQL Server deployment |
| `README.md` | Complete documentation |
| `QUICKSTART.md` | Step-by-step setup guide |
| `SIMPLE_MODE.md` | Alternative deployment without IAP |
| `SCRIPTS.md` | Helper scripts for daily operations |

---

## Modified Files

| File | Changes |
|------|---------|
| `infra/compute.sql-linux.tf` | Added persistent disk, lifecycle protection, changed startup script |
| `infra/firewall.tf` | Added IAP firewall rule |
| `infra/variables.tf` | Added `disk_size_gb` variable |
| `infra/outputs.tf` | Added disk name, SA email, connection string template |

---

## Workflow Comparison

### Old Workflow (Manual)
```
1. terraform apply
2. Wait for VM startup script (5+ minutes)
3. SSH to VM if startup fails
4. Manually fix Docker/SQL issues
5. VM runs 24/7
```

### New Workflow (Automated)
```
1. terraform apply (VM only, ~2 minutes)
2. Go to GitHub Actions → Run workflow
3. Wait 2 minutes for SQL Server deployment
4. Done! Data persists across rebuilds.

Daily:
- Evening: terraform destroy -target=...sqlvm (save $$$)
- Morning: terraform apply + GitHub Actions deploy
```

---

## Cost Analysis

### Scenario 1: 24/7 Uptime (Old Approach)
| Resource | Cost/Month |
|----------|------------|
| VM (e2-standard-2) | $49 |
| Disk (50GB) | $8 |
| **Total** | **$57/month** |

### Scenario 2: Tear Down Nights & Weekends (New Approach)
| Resource | Cost/Month |
|----------|------------|
| VM (8 hrs/day, M-F) | $13 |
| Persistent Disk (100GB SSD) | $17 |
| Static IP (allocated) | $7 |
| **Total** | **$37/month** |
| **Savings** | **$20/month (35%)** |

### Scenario 3: Tear Down When Not in Use
| Resource | Cost/Month |
|----------|------------|
| VM (destroyed) | $0 |
| Persistent Disk (100GB SSD) | $17 |
| Static IP (allocated) | $7 |
| **Total** | **$24/month** |
| **Savings** | **$33/month (58%)** |

---

## Migration Steps

### 1. Backup Current Data (IMPORTANT!)
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourPassword' -C \
  -Q "BACKUP DATABASE [DemoDB] TO DISK = N'/var/opt/mssql/data/DemoDB_backup.bak'"
```

### 2. Apply Infrastructure Changes
```bash
cd infra
terraform apply
```

**Terraform will:**
- Create persistent disk (new resource)
- Update VM to use new startup script
- Attach persistent disk to VM
- Create IAP firewall rule
- Create GitHub Actions service account

### 3. Copy Existing Data to Persistent Disk (if needed)
```bash
# SSH to VM
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap

# Copy existing SQL Server data
sudo docker cp mssql:/var/opt/mssql/data /mnt/sqldata/
sudo docker cp mssql:/var/opt/mssql/log /mnt/sqldata/

# Fix permissions
sudo chown -R 10001:10001 /mnt/sqldata
```

### 4. Configure GitHub Secrets
Follow steps in `QUICKSTART.md` to add:
- `GCP_PROJECT_ID`
- `GCP_SA_KEY`
- `SQL_SA_PASSWORD`
- `SQL_CI_PASSWORD`

### 5. Test Deployment
```bash
# Destroy VM
terraform destroy -target=google_compute_instance.sqlvm -auto-approve

# Recreate VM
terraform apply -auto-approve

# Deploy SQL Server via GitHub Actions
# Go to: https://github.com/YOUR_REPO/actions
# Run: Deploy SQL Server to GCP
```

### 6. Verify Data Persistence
```bash
# Connect to SQL Server
# Verify your databases and data are intact
```

---

## Rollback Plan (If Needed)

If something goes wrong, you can rollback:

### 1. Restore from Backup
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo docker cp /mnt/sqldata/data/DemoDB_backup.bak mssql:/var/opt/mssql/data/
sudo docker exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'Password' -C \
  -Q "RESTORE DATABASE [DemoDB] FROM DISK = N'/var/opt/mssql/data/DemoDB_backup.bak' WITH REPLACE"
```

### 2. Revert to Old Startup Script
```bash
# Use git to restore old compute.sql-linux.tf
git checkout HEAD~1 infra/compute.sql-linux.tf
terraform apply
```

---

## Testing Checklist

After migration, verify:

- [ ] VM spins up successfully
- [ ] Persistent disk mounts at `/mnt/sqldata`
- [ ] Docker is installed and running
- [ ] GitHub Actions can SSH via IAP
- [ ] SQL Server container deploys successfully
- [ ] Database `DemoDB` exists
- [ ] User `ci_user` has `db_owner` role
- [ ] Can connect from local machine
- [ ] Tear down VM → data persists
- [ ] Spin up VM → data is still there
- [ ] Static IP never changes

---

## Next Steps

1. ✅ Read `QUICKSTART.md` for setup instructions
2. ✅ Test tear down/spin up cycle
3. ✅ Set up helper scripts from `SCRIPTS.md`
4. 🔄 Consider scheduled tear down/spin up (save more $$$)
5. 🔄 Set up automated backups to Cloud Storage
6. 🔄 Monitor costs in GCP Billing console

---

## Support

**Questions?** Check these docs:
- `README.md` - Complete documentation
- `QUICKSTART.md` - Setup guide
- `SIMPLE_MODE.md` - Alternative deployment
- `SCRIPTS.md` - Helper scripts

**Issues?** Check:
- Startup script logs: `gcloud compute instances get-serial-port-output sql-linux-vm`
- Docker logs: `sudo docker logs mssql`
- GitHub Actions logs: Actions tab → View workflow run

---

**Version:** 1.0.0  
**Migration Date:** {{ date }}  
**Project:** demo-gcp-terraform
