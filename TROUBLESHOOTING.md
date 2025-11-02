# Troubleshooting Guide

This guide documents common issues encountered during development and deployment, along with their solutions.

---

## Table of Contents

- [SQL Server Issues](#sql-server-issues)
- [VM Creation Issues](#vm-creation-issues)
- [SQL Server Deployment Issues](#sql-server-deployment-issues)
- [Connection Issues](#connection-issues)
- [Qodo Merge Issues](#qodo-merge-issues)
- [Terraform State Issues](#terraform-state-issues)
- [Performance Issues](#performance-issues)

---

## SQL Server Issues

### ❌ Problem: sqlcmd not found or connection fails

**Root Cause:** SQL Server 2022 uses `/opt/mssql-tools18` instead of `/opt/mssql-tools`

**Solution:**
```bash
# Correct command for SQL Server 2022
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'password' -C -Q "SELECT @@VERSION"
```

**Files Fixed:**
- ✅ `vm-startup.sh`
- ✅ `linux-first-boot.sh.tftpl`

**Note:** The `-C` flag is required to trust the server certificate.

---

### ❌ Problem: Database files not on persistent disk after manual setup

**Root Cause:** Docker volumes not explicitly mounted to `/mnt/sqldata`

**Solution:**
```bash
# Correct Docker run command with volume mounts
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$PASSWORD" \
  -p 1433:1433 --name mssql --hostname mssql \
  -v /mnt/sqldata/mssql/data:/var/opt/mssql/data \
  -v /mnt/sqldata/mssql/log:/var/opt/mssql/log \
  -v /mnt/sqldata/mssql/secrets:/var/opt/mssql/secrets \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

**Files Fixed:**
- ✅ `vm-startup.sh`
- ✅ `vm-prep.sh.tftpl`

**Verification:**
```bash
# Check if database files are on persistent disk
ls -lh /mnt/sqldata/mssql/data/
# Should show: DemoDB.mdf, DemoDB_log.ldf, etc.
```

---

### ❌ Problem: ci_user not created during initial deployment

**Root Cause:** Startup script errors prevented user creation SQL from executing

**Solution:**
1. Fixed sqlcmd path issues (see above)
2. Ensured `init-database.sql` includes user creation
3. Verified script uploads to GCS and executes successfully

**Manual Fix (if needed):**
```bash
# SSH to VM
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap

# Connect to SQL Server
sudo docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YOUR_SA_PASSWORD' -C

# Create user
CREATE LOGIN ci_user WITH PASSWORD = 'YOUR_CIUSER_PASSWORD';
GO
USE DemoDB;
GO
CREATE USER ci_user FOR LOGIN ci_user;
GO
ALTER ROLE db_owner ADD MEMBER ci_user;
GO
```

---

## VM Creation Issues

### ❌ Problem: Terraform fails with "resource already exists"

**Solution:** Workflow automatically imports existing resources. If import fails:

```bash
cd infra

# Manually import stuck resources
terraform import google_compute_address.sqlvm_ip projects/YOUR_PROJECT/regions/us-central1/addresses/sqlvm-static-ip
terraform import google_compute_disk.sql_data projects/YOUR_PROJECT/zones/us-central1-a/disks/sql-data

# Then apply
terraform apply
```

---

### ❌ Problem: Startup script fails (Docker not installing)

**Check serial port logs:**
```bash
gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a | more
```

**Common causes:**

1. **Line ending issues (CRLF vs LF)**
   ```powershell
   # Convert to LF (PowerShell)
   (Get-Content .\infra\scripts\vm-prep.sh.tftpl -Raw) -replace "`r`n", "`n" | Set-Content -NoNewline .\infra\scripts\vm-prep.sh.tftpl
   ```

2. **Package installation timeout**
   - Check VM internet connectivity
   - Verify GCP APIs are enabled

3. **Disk already formatted**
   - Expected behavior, script detects and skips formatting

---

### ❌ Problem: Path mismatch between vm-prep.sh and vm-startup.sh

**Root Cause:** `vm-prep.sh` created `/mnt/sqldata/data`, but `vm-startup.sh` expected `/mnt/sqldata/mssql/data`

**Solution:** Updated `vm-prep.sh` to create consistent subdirectory structure:
```bash
mkdir -p "$MOUNT_POINT/mssql/data"
mkdir -p "$MOUNT_POINT/mssql/log"
mkdir -p "$MOUNT_POINT/mssql/secrets"
chown -R 10001:10001 "$MOUNT_POINT/mssql"
```

**Verification:**
```bash
# Check directory structure
tree /mnt/sqldata
# Should show:
# /mnt/sqldata/
# └── mssql/
#     ├── data/
#     ├── log/
#     └── secrets/
```

---

## SQL Server Deployment Issues

### ❌ Problem: GitHub Actions can't SSH to VM

**Check IAP permissions:**
```bash
gcloud projects get-iam-policy YOUR_PROJECT \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deployer*"
```

**Required roles:**
- ✅ `roles/compute.osLogin`
- ✅ `roles/iap.tunnelResourceAccessor`
- ✅ `roles/compute.viewer`

**Grant missing role:**
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT \
  --member="serviceAccount:github-actions-deployer@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

---

### ❌ Problem: SQL Server container fails to start

**Check container logs:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap
sudo docker logs mssql
```

**Common causes:**

1. **Password complexity requirements not met**
   - Must be 8+ characters
   - Must include uppercase, lowercase, digit, special character
   - Example: `MyStr0ng#Pass`

2. **Insufficient memory**
   - SQL Server requires minimum 2GB RAM
   - Current VM: e2-standard-2 (2 vCPU, 8GB RAM) ✅

3. **Disk permission issues**
   ```bash
   # Fix ownership (SQL Server runs as UID 10001)
   sudo chown -R 10001:10001 /mnt/sqldata
   ```

4. **Old container with different password**
   - Solution: Workflow always removes old container before creating new one
   - Check deployment script removes container: `sudo docker rm -f mssql`

---

### ❌ Problem: Can't access Secret Manager from VM

**Check VM service account scope:**
```bash
gcloud compute instances describe sql-linux-vm \
  --zone=us-central1-a \
  --format="get(serviceAccounts[0].scopes)"
```

**Expected:** `https://www.googleapis.com/auth/cloud-platform`

**If wrong scope, update Terraform:**
```hcl
# infra/compute.sql-linux.tf
service_account {
  email  = google_service_account.vm_runtime.email
  scopes = ["cloud-platform"]  # Not ["logging-write", "monitoring-write"]
}
```

---

## Connection Issues

### ❌ Problem: Can't connect to SQL Server from local machine

**Check firewall allows your IP:**
```bash
# Get your current IP
curl -s ifconfig.me

# Check firewall rule
gcloud compute firewall-rules describe allow-sql-1433-admin --format="get(sourceRanges)"
```

**Update firewall if IP changed:**
```bash
cd infra
# Edit terraform.tfvars: admin_ip_cidr = "YOUR_NEW_IP/32"
terraform apply -target=google_compute_firewall.allow_sql_1433_admin
```

---

### ❌ Problem: Connection refused on port 1433

**Verify SQL Server is running:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap

# Check container status
sudo docker ps | grep mssql

# Check port listening
sudo netstat -tlnp | grep 1433

# Test local connection
sudo docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P 'YOUR_PASSWORD' \
  -C \
  -Q "SELECT @@VERSION"
```

**Common issues:**
- Container not running: `sudo docker start mssql`
- Port not exposed: Check Docker run command includes `-p 1433:1433`
- Firewall blocking: Verify GCP firewall rule and local firewall

---

## Qodo Merge Issues

### ❌ Problem: Qodo bot doesn't respond to `/review` comment

**Check GitHub App installation:**
1. Go to **Settings → Integrations → Applications**
2. Verify **Qodo Merge** is installed
3. Check repository access includes `demo-gcp-terraform`

**Reinstall if needed:**
- Visit https://github.com/apps/qodo-merge
- Click **Configure** → Select repositories

---

### ❌ Problem: Manual workflow dispatch fails (missing PR number)

**Solution:** Workflow accepts PR number OR full URL

```
# Both work:
42
https://github.com/chiranjib555/demo-gcp-terraform/pull/42
```

**Fallback order:**
1. `inputs.pr_number` (manual trigger)
2. `pull_request.number` (PR trigger)
3. `issue.number` (comment trigger)

---

### ❌ Problem: Qodo Merge workflow errors: "Unrecognized named-value: 'env'"

**Root Cause:** `env` context cannot be accessed in job-level `if` conditions

**Solution:**
- Changed `env.QODO_ENABLED` to `vars.QODO_ENABLED` in `if` condition
- Moved `env:` block from workflow level to job level

```yaml
jobs:
  qodo:
    if: >
      (github.event_name == 'pull_request' && vars.QODO_ENABLED == 'true') ||
      ...
    env:
      QODO_ENABLED: ${{ vars.QODO_ENABLED || 'false' }}
```

**Files Fixed:**
- ✅ `qodo-merge.yml`

---

## Terraform State Issues

### ❌ Problem: Terraform state out of sync

**View current state:**
```bash
cd infra
terraform state list
```

**Remove resource from state (if deleted manually in GCP):**
```bash
terraform state rm google_compute_instance.sqlvm
```

**Re-import resource:**
```bash
terraform import google_compute_instance.sqlvm projects/YOUR_PROJECT/zones/us-central1-a/instances/sql-linux-vm
```

---

## Performance Issues

### ❌ Problem: SQL Server slow or unresponsive

**Check VM resources:**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap

# CPU and memory usage
top

# Disk I/O
iostat -x 1

# SQL Server container stats
sudo docker stats mssql
```

**Upgrade VM if needed:**
```hcl
# infra/compute.sql-linux.tf
machine_type = "e2-standard-4"  # 4 vCPU, 16GB RAM
```

**Upgrade disk to higher IOPS:**
```hcl
# infra/disk.sql-data.tf
type = "pd-ssd"  # Already using SSD ✅
size = 200       # Increase size for more throughput
```

---

## General Debugging Tips

### Enable Verbose Logging

**Terraform:**
```bash
export TF_LOG=DEBUG
terraform apply
```

**Docker:**
```bash
# Run container with verbose logging
sudo docker run ... -e MSSQL_ENABLE_LOG=1 ...
```

**GitHub Actions:**
- Add `ACTIONS_STEP_DEBUG` secret with value `true`
- Adds debug output to workflow runs

---

### Useful Commands

**Check all GCP resources:**
```bash
# List VMs
gcloud compute instances list

# List disks
gcloud compute disks list

# List static IPs
gcloud compute addresses list

# List firewall rules
gcloud compute firewall-rules list
```

**Docker troubleshooting:**
```bash
# Container logs
sudo docker logs mssql

# Container inspect
sudo docker inspect mssql

# Execute command in container
sudo docker exec -it mssql bash

# Remove all containers (fresh start)
sudo docker rm -f $(sudo docker ps -aq)
```

**SQL Server logs:**
```bash
# Error log
sudo docker exec mssql cat /var/opt/mssql/log/errorlog

# Agent log
sudo docker exec mssql cat /var/opt/mssql/log/sqlagent.out
```

---

## Getting Help

If you encounter an issue not covered here:

1. **Check Logs:**
   - VM: `gcloud compute instances get-serial-port-output sql-linux-vm`
   - Docker: `sudo docker logs mssql`
   - SQL Server: `sudo docker exec mssql cat /var/opt/mssql/log/errorlog`

2. **Verify Configuration:**
   - `terraform.tfvars` has correct values
   - GitHub Secrets are set correctly
   - GCP APIs are enabled

3. **Review Documentation:**
   - [GCP IAP for TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)
   - [SQL Server on Linux](https://learn.microsoft.com/en-us/sql/linux/)
   - [GitHub Actions with GCP](https://github.com/google-github-actions/auth)

4. **Create an Issue:**
   - Include error messages
   - Attach relevant logs
   - Describe steps to reproduce
