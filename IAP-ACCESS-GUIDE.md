# 🔒 IAP-Only Access Guide

Your GCP infrastructure is now configured for **IAP-only access**. This means you can connect from ANY IP address without firewall updates!

## ✅ Benefits

- ✅ **Works from any IP** - Home, office, coffee shop, anywhere!
- ✅ **No firewall maintenance** - IP changes don't break access
- ✅ **More secure** - No public internet exposure
- ✅ **Google-managed authentication** - Built-in security

---

## 🚀 How to Connect

### **SSH Access**

**Option 1: Use the helper script (Easiest)**
```powershell
.\ssh-iap.ps1
```

**Option 2: Manual command**
```powershell
gcloud compute ssh sql-linux-vm `
    --zone=us-central1-a `
    --tunnel-through-iap `
    --project=praxis-gantry-475007-k0
```

---

### **SQL Server Access**

**Option 1: Use the helper script (Recommended)**
```powershell
# Terminal 1: Start the tunnel (keep running)
.\sql-tunnel-iap.ps1

# Terminal 2: Connect with your SQL client
# Server:   localhost,1433
# Database: DemoDB
# User:     ci_user
# Password: ChangeMe_UseStrongPwd#2025!
```

**Option 2: Manual tunnel**
```powershell
gcloud compute start-iap-tunnel sql-linux-vm 1433 `
    --local-host-port=localhost:1433 `
    --zone=us-central1-a `
    --project=praxis-gantry-475007-k0
```

**Connection String (via tunnel):**
```
Server=localhost,1433;Database=DemoDB;User Id=ci_user;Password=ChangeMe_UseStrongPwd#2025!;TrustServerCertificate=True;
```

---

## 📝 Usage Examples

### **Quick SSH Command**
```powershell
# Run a single command via SSH
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --project=praxis-gantry-475007-k0 --command="docker ps"
```

### **SQL Query via Tunnel**
```powershell
# In one terminal, start tunnel:
.\sql-tunnel-iap.ps1

# In another terminal or SSMS:
sqlcmd -S localhost,1433 -U ci_user -P 'ChangeMe_UseStrongPwd#2025!' -d DemoDB -Q "SELECT * FROM Customers;"
```

---

## 🔄 After Terraform Destroy/Apply

**Great news!** Since IAP doesn't depend on your IP address:
1. Run `terraform destroy` (when needed)
2. Run `terraform apply` (to recreate)
3. ✅ **Everything works immediately** - No IP updates needed!

---

## ⚙️ Re-enabling Public Access (If Needed)

If you ever need direct public access again:

1. Edit `infra/firewall.tf`
2. Uncomment the `google_compute_firewall.ssh` and `google_compute_firewall.sql_1433` resources
3. Run `terraform apply`

---

## 🛠️ Troubleshooting

### **"Permission denied" errors**
Make sure you're authenticated:
```powershell
gcloud auth login
```

### **"Failed to connect to port" errors**
1. Ensure VM is running: `gcloud compute instances list`
2. Check IAP permissions: You should have `roles/iap.tunnelResourceAccessor`

### **Tunnel dies unexpectedly**
Just restart the tunnel script - data is safe on the VM!

---

## 📚 Helper Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `ssh-iap.ps1` | SSH to VM via IAP | `.\ssh-iap.ps1` |
| `sql-tunnel-iap.ps1` | Create SQL tunnel | `.\sql-tunnel-iap.ps1` |
| `check-status.ps1` | Check VM status | `.\check-status.ps1` |

---

## 🎉 You're All Set!

No more IP change headaches! Connect from anywhere, anytime! 🚀
