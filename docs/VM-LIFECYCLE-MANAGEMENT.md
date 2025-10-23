# SQL Server VM Lifecycle Management

## Overview

This guide explains how to **destroy** and **recreate** the SQL Server VM to save costs during inactivity, while **preserving your data and IP address**.

## 🎯 Use Case: Demo/Dev Environment Cost Optimization

Perfect for:
- **Demo projects** - Destroy when not presenting, recreate on-demand
- **Development environments** - Only pay when actively developing
- **Testing** - Spin up/down between test cycles
- **Training/Learning** - Save costs when not in use

## 💰 Cost Savings

| State | Monthly Cost | What's Running |
|-------|-------------|----------------|
| **VM Running** | ~$17/month | Compute + Disk + IP |
| **VM Destroyed** | ~$3.50/month | Disk + IP (no compute) |
| **Savings** | ~$13.50/month | ~80% reduction! |

### Cost Breakdown:
- **Compute (e2-standard-2)**: ~$14/month → **$0** when destroyed
- **Persistent Disk (100GB SSD)**: ~$2/month → **Kept** (preserves your data)
- **Static IP**: ~$1.50/month → **Kept** (same IP after recreate)

## 🛡️ What's Protected

These resources are **never deleted** (Terraform lifecycle protection):

✅ **Static IP Address** (`sqlvm-ip`)
- Same IP address after recreate
- No need to update connection strings
- Currently: `34.57.37.222`

✅ **Persistent Disk** (`sql-data-disk`)
- All SQL Server data preserved
- Database files intact
- Transaction logs intact
- Container data volumes intact

✅ **Infrastructure**
- VPC network
- Subnets
- Firewall rules
- Service accounts
- IAM permissions
- Secret Manager secrets

## 🎮 GitHub Actions Workflow

### Available Actions

Access via: **GitHub → Actions → Deploy SQL Server (Startup Script Pattern)**

#### 1. 🚀 **deploy** - Full Deployment
- Uploads latest SQL scripts to GCS
- Updates startup script
- Resets VM and waits for completion
- Verifies deployment
- **Duration**: 3-5 minutes

#### 2. 🔄 **restart** - Quick Reboot
- Checks VM status
- Restarts (if running) or starts (if stopped)
- Startup script runs automatically
- **Duration**: 5 seconds (+ ~2 min boot time)

#### 3. 🛑 **stop** - Stop VM
- Stops the VM (no compute charges)
- Disk and IP kept
- **Duration**: 5 seconds
- **Savings**: ~$14/month

#### 4. 💣 **destroy** - Delete VM
- **Deletes the VM completely**
- Static IP preserved
- Persistent disk preserved
- **Duration**: 30 seconds
- **Savings**: ~$14/month
- ⚠️ **WARNING**: Cannot undo (must recreate)

#### 5. 🏗️ **create** - Recreate VM
- Uses Terraform to recreate VM
- Attaches existing persistent disk
- Uses existing static IP
- Startup script runs automatically
- **Duration**: 2-3 minutes
- **Result**: VM identical to original

## 📋 Workflow Usage

### Scenario 1: Weekend/Holiday Shutdown

**Friday Evening:**
```
1. Go to GitHub Actions
2. Select workflow: Deploy SQL Server (Startup Script Pattern)
3. Click "Run workflow"
4. Select action: destroy
5. Run workflow
```

**Monday Morning:**
```
1. Go to GitHub Actions
2. Select workflow: Deploy SQL Server (Startup Script Pattern)
3. Click "Run workflow"
4. Select action: create
5. Run workflow
6. Wait 2-3 minutes for VM to boot and SQL Server to start
```

### Scenario 2: Extended Downtime (Weeks/Months)

If you won't use the VM for extended periods:

```bash
# Destroy the VM
Run GitHub Actions with action: destroy

# Cost during downtime: ~$3.50/month (disk + IP only)
# Your data is safe on the persistent disk
```

When you need it again:
```bash
# Recreate the VM
Run GitHub Actions with action: create

# Everything restored: same IP, same data, same configuration
```

### Scenario 3: Daily Development

**End of Day:**
```
Action: stop
Cost: ~$3.50/month + hourly compute for time VM was running
```

**Start of Day:**
```
Action: restart
Duration: ~2 minutes to boot
```

## 🔍 Getting Connection Information

After recreating the VM, your **IP address stays the same**, but you can verify:

### Option 1: PowerShell Script (Windows)
```powershell
.\scripts\Get-ConnectionInfo.ps1
```

### Option 2: Bash Script (Linux/Mac)
```bash
./scripts/get-connection-info.sh
```

### Option 3: Terraform Outputs
```bash
cd infra
terraform output
```

### Option 4: Gcloud Command
```bash
gcloud compute instances describe sql-linux-vm \
  --zone us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

## 📊 Connection Strings

The connection scripts generate connection strings for:
- **ADO.NET / C# / .NET**
- **JDBC / Java**
- **ODBC**
- **SQLAlchemy / Python**
- **Azure Data Studio / SSMS**

Example output:
```
Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=<YOUR_PASSWORD>;TrustServerCertificate=True;
```

## ⚠️ Important Notes

### Data Safety
- ✅ **Your data is SAFE** - Persistent disk is never deleted
- ✅ **IP address is STABLE** - Static IP is never deleted
- ✅ **Configuration preserved** - Startup script stored in VM metadata

### Limitations
- ❌ Cannot "destroy" then "restart" - You must "create" first
- ❌ Boot disk is deleted (but that's just the OS, not your data)
- ❌ Ephemeral data in `/tmp` or non-persistent volumes is lost

### Recovery from Destroy
If you accidentally destroy the VM:
1. Run workflow with "create" action
2. Wait 2-3 minutes
3. Your data is back!

The persistent disk and static IP are protected by Terraform lifecycle rules:
```hcl
lifecycle {
  prevent_destroy = true
}
```

## 🔧 Manual Management

### Using Terraform Directly

**Destroy VM:**
```bash
cd infra
terraform destroy -target=google_compute_instance.sqlvm
```

**Recreate VM:**
```bash
cd infra
terraform apply -target=google_compute_instance.sqlvm
```

**Full infrastructure status:**
```bash
cd infra
terraform state list
terraform show
```

### Using Gcloud Commands

**Destroy VM:**
```bash
gcloud compute instances delete sql-linux-vm --zone us-central1-a
```

**Recreate VM:**
```bash
# Must use Terraform - gcloud create requires many parameters
cd infra && terraform apply -target=google_compute_instance.sqlvm
```

## 📈 Cost Tracking

Track your actual costs in GCP Console:
- Go to: **Billing → Reports**
- Filter by: **Project = praxis-gantry-475007-k0**
- Filter by: **Service = Compute Engine**

You should see ~80% cost reduction when VM is destroyed.

## 🎓 Best Practices

1. **Destroy when not in use** - Even overnight saves money
2. **Use 'stop' for short breaks** - Faster than destroy/create
3. **Use 'destroy' for extended downtime** - Weeks/months
4. **Test 'create' regularly** - Ensure you can recover quickly
5. **Document downtime** - Let users know when VM is down

## 🆘 Troubleshooting

### Problem: Workflow fails with "VM does not exist"
**Solution**: Use "create" action first, then "deploy"

### Problem: After create, can't connect to SQL Server
**Solution**: 
- Wait 2-3 minutes for startup script to complete
- Check serial console: `gcloud compute instances get-serial-port-output sql-linux-vm`
- Run "deploy" action to verify

### Problem: Data missing after recreate
**Solution**: 
- Check persistent disk exists: `gcloud compute disks list`
- The disk should be: `sql-data-disk` (100GB)
- If disk exists, data is there - SQL Server might need time to attach

### Problem: Different IP address after recreate
**Solution**: 
- This shouldn't happen - static IP is protected
- Verify: `gcloud compute addresses describe sqlvm-ip --region us-central1`
- If IP changed, update firewall rules and connection strings

## 📚 Additional Resources

- [GCP Compute Engine Pricing](https://cloud.google.com/compute/pricing)
- [Persistent Disk Documentation](https://cloud.google.com/compute/docs/disks)
- [Static IP Addresses](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
- [Terraform Lifecycle Meta-Arguments](https://www.terraform.io/language/meta-arguments/lifecycle)

---

**Last Updated**: October 23, 2025  
**Status**: ✅ Production Ready
