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
# Server:   localhost,51433
# Database: DemoDB
# User:     ci_user
# Password: ChangeMe_UseStrongPwd#2025!
```

**IMPORTANT:** Port 1433 is typically used by local SQL Server instances. The script uses **port 51433** to avoid conflicts.

**Option 2: Manual tunnel**
```powershell
gcloud compute start-iap-tunnel sql-linux-vm 1433 `
    --local-host-port=localhost:51433 `
    --zone=us-central1-a `
    --project=praxis-gantry-475007-k0
```

**Connection String (via tunnel):**
```
Server=localhost,51433;Database=DemoDB;User Id=ci_user;Password=ChangeMe_UseStrongPwd#2025!;TrustServerCertificate=True;
```

**Verify tunnel before connecting:**
```powershell
Test-NetConnection -ComputerName localhost -Port 51433
# Should show: TcpTestSucceeded : True
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
sqlcmd -S localhost,51433 -U ci_user -P 'ChangeMe_UseStrongPwd#2025!' -d DemoDB -Q "SELECT * FROM Customers;"
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
gcloud config set project praxis-gantry-475007-k0
```

Verify you have IAP access role:
```powershell
gcloud projects get-iam-policy praxis-gantry-475007-k0 --flatten="bindings[].members" --filter="bindings.role:roles/iap.tunnelResourceAccessor"
```

### **"Unable to open socket on port" errors**
The port is already in use. Options:

**Option 1:** Kill existing tunnel processes
```powershell
Get-Process | Where-Object {$_.ProcessName -eq "gcloud"} | Stop-Process -Force
```

**Option 2:** Use a different local port
```powershell
# Edit sql-tunnel-iap.ps1 and change 51433 to another port like 52433
gcloud compute start-iap-tunnel sql-linux-vm 1433 --local-host-port=localhost:52433 --zone=us-central1-a --project=praxis-gantry-475007-k0
```

### **"Remote computer refused the connection" in SSMS**
This means the IAP tunnel is NOT running. Make sure:

1. ✅ Tunnel script is running in a separate PowerShell window
2. ✅ Verify tunnel is listening:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 51433
   ```
   Should show: `TcpTestSucceeded : True`

3. ✅ SSMS server name matches tunnel port: `localhost,51433` (comma, not colon)

### **"Failed to connect to port" errors**
1. Ensure VM is running: 
   ```powershell
   gcloud compute instances list --project=praxis-gantry-475007-k0 --filter="name=sql-linux-vm"
   ```
2. Check IAP firewall rule allows port 1433:
   ```powershell
   gcloud compute firewall-rules describe allow-iap-ssh --project=praxis-gantry-475007-k0
   ```
   Should show: `tcp:22,tcp:1433`

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
