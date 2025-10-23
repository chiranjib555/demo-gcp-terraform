# 🌐 Get SQL Server Connection Info from Anywhere

## Quick Start (No Local Setup Required!)

### Option 1: One-Line Cloud Shell Command ⚡

Open [Google Cloud Shell](https://console.cloud.google.com/?cloudshell=true) and run:

```bash
curl -s https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh | bash
```

**That's it!** You'll get:
- ✅ VM status (running/stopped)
- ✅ External & internal IP addresses  
- ✅ Connection strings for all major tools
- ✅ JSON output for automation
- ✅ Quick action commands

---

### Option 2: Download and Run

```bash
# Download the script
gsutil cp gs://praxis-sql-bootstrap/get-connection-info-cloud.sh .

# Make it executable
chmod +x get-connection-info-cloud.sh

# Run it
./get-connection-info-cloud.sh
```

---

### Option 3: Local Machine (With VS Code / Git)

**Windows (PowerShell):**
```powershell
.\scripts\Get-ConnectionInfo.ps1
```

**Linux/Mac (Bash):**
```bash
./scripts/get-connection-info.sh
```

---

## 📊 What You'll Get

```
╔════════════════════════════════════════════════════════════════════╗
║         SQL Server VM Connection Information (Cloud Shell)         ║
╚════════════════════════════════════════════════════════════════════╝

📊 VM STATUS
═══════════════════════════════════════════════════════════════════
   VM Name:      sql-linux-vm
   Project:      praxis-gantry-475007-k0
   Zone:         us-central1-a
   Status:       RUNNING

🌐 NETWORK INFORMATION
═══════════════════════════════════════════════════════════════════
   External IP:  34.57.37.222
   Internal IP:  10.0.1.2
   SQL Port:     1433

🔌 CONNECTION STRINGS
═══════════════════════════════════════════════════════════════════

▶ ADO.NET / C# / .NET:
Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=<PASSWORD>;TrustServerCertificate=True;Encrypt=True;

▶ JDBC / Java:
jdbc:sqlserver://34.57.37.222:1433;databaseName=DemoDB;user=ci_user;password=<PASSWORD>;encrypt=true;trustServerCertificate=true;

▶ ODBC:
Driver={ODBC Driver 18 for SQL Server};Server=34.57.37.222,1433;Database=DemoDB;Uid=ci_user;Pwd=<PASSWORD>;Encrypt=yes;TrustServerCertificate=yes;

▶ SQLAlchemy / Python:
mssql+pyodbc://ci_user:<PASSWORD>@34.57.37.222:1433/DemoDB?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes

▶ Azure Data Studio / SSMS:
  Server:         34.57.37.222,1433
  Database:       DemoDB
  Authentication: SQL Server Authentication
  Username:       ci_user
  Password:       <Get from Secret Manager>
  Encryption:     Mandatory
  Trust Cert:     Yes

🔑 SQL PASSWORD
═══════════════════════════════════════════════════════════════════
To retrieve the password:
gcloud secrets versions access latest --secret=sql-ci-password --project=praxis-gantry-475007-k0

📋 JSON OUTPUT (for automation/scripts)
═══════════════════════════════════════════════════════════════════
{
  "vm_name": "sql-linux-vm",
  "project_id": "praxis-gantry-475007-k0",
  "zone": "us-central1-a",
  "status": "RUNNING",
  "external_ip": "34.57.37.222",
  "internal_ip": "10.0.1.2",
  "database": "DemoDB",
  "username": "ci_user",
  "port": 1433,
  "connection_string_template": "Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=<PASSWORD>;TrustServerCertificate=True;",
  "password_command": "gcloud secrets versions access latest --secret=sql-ci-password --project=praxis-gantry-475007-k0"
}
```

---

## 🎯 Use Cases

### 1. **After VM Recreate**
You destroyed the VM to save costs and recreated it. Verify the IP address:
```bash
curl -s https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh | bash
```

### 2. **Working from Different Computer**
You're on a different machine without VS Code:
- Open Cloud Shell (no install needed)
- Run the one-liner
- Copy connection string

### 3. **Share with Team Members**
Team member needs connection info:
```bash
# Send them this link:
https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh

# They run:
curl -s https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh | bash
```

### 4. **Automation Scripts**
Use JSON output in CI/CD or automation:
```bash
# Get JSON output and parse
curl -s https://storage.googleapis.com/praxis-sql-bootstrap/get-connection-info-cloud.sh | bash | grep -A 20 "JSON OUTPUT"
```

---

## 🔒 Security Notes

### Public Script, Private Data
- ✅ **Script is public** - Anyone can run it
- ✅ **But it requires GCP authentication** - Only authorized users get data
- ✅ **Passwords NOT in script** - Retrieved from Secret Manager (requires IAM permissions)

### Who Can Access?
Only users with:
1. GCP account access to your project
2. `compute.instances.get` permission
3. `secretmanager.versions.access` permission (for password)

---

## 🛠️ Troubleshooting

### Error: "VM does not exist"
**Solution**: VM was destroyed. Recreate it:
- GitHub Actions → Run workflow with `create` action
- Or: `cd infra && terraform apply -target=google_compute_instance.sqlvm`

### Error: "Permission denied"
**Solution**: You need GCP access. Ask project owner to grant you:
```bash
gcloud projects add-iam-policy-binding praxis-gantry-475007-k0 \
  --member="user:your-email@example.com" \
  --role="roles/compute.viewer"
```

### Script shows "VM is not RUNNING"
**Solution**: Start the VM:
```bash
gcloud compute instances start sql-linux-vm --zone us-central1-a
```

Or use GitHub Actions: Run workflow with `restart` action

---

## 📚 Related Documentation

- [VM Lifecycle Management](../docs/VM-LIFECYCLE-MANAGEMENT.md) - Destroy/Create workflow
- [Startup Script Migration](MIGRATION_TO_STARTUP_SCRIPT.md) - Architecture overview
- [GCP Cloud Shell Docs](https://cloud.google.com/shell/docs)

---

## 🔄 Script Updates

The script is automatically updated on every deployment:
- GitHub Actions workflow uploads latest version to GCS
- Always run the latest version with the one-liner command

Manual update:
```bash
gsutil cp scripts/get-connection-info-cloud.sh gs://praxis-sql-bootstrap/
```

---

**Last Updated**: October 23, 2025  
**Script Location**: `gs://praxis-sql-bootstrap/get-connection-info-cloud.sh`  
**Status**: ✅ Production Ready
