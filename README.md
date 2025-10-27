# GCP SQL Server Infrastructure with Automated Deployment

[![Terraform](https://img.shields.io/badge/Terraform-1.7.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![GCP](https://img.shields.io/badge/GCP-Cloud-4285F4?logo=google-cloud)](https://cloud.google.com/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)

This project automates the deployment of **SQL Server 2022 Developer Edition** on **Google Cloud Platform** using **Terraform** and **GitHub Actions**. The infrastructure uses persistent storage and static IPs to ensure data stability across VM lifecycle operations, with cost-optimized tear-down/spin-up workflows.

## 🎯 Key Features

- **🔄 Automated VM Lifecycle**: Create/destroy VMs via GitHub Actions workflows
- **💾 Persistent Data**: 100GB SSD disk survives VM destruction
- **🌐 Static IP**: Stable connection endpoint across rebuilds
- **🐳 Containerized SQL Server**: Docker-based deployment for portability
- **🔐 Secure Access**: IAP tunneling, service account authentication, firewall rules
- **🤖 AI-Powered PR Reviews**: Qodo Merge integration for code quality
- **💰 Cost Optimized**: Tear down VMs when not in use, preserve data

---

## 📋 Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflows                                        │
│  ├─ manage-vm-lifecycle.yml   (Create/Destroy VM)               │
│  ├─ deploy-sql-startup.yml    (Deploy SQL Server via SSH)       │
│  └─ qodo-merge.yml            (AI PR Reviews)                   │
└────────────────┬─────────────────────────────────────────────────┘
                 │ GCP Authentication (Service Account)
                 ▼
┌──────────────────────────────────────────────────────────────────┐
│  Google Cloud Platform (praxis-gantry-475007-k0)                │
│  ├─ Region: us-central1-a                                        │
│  ├─ Service Accounts:                                            │
│  │  ├─ github-actions-deployer (Terraform + SSH)                │
│  │  └─ vm-runtime (Secret Manager access)                       │
│  ├─ VPC Network: sql-vpc                                         │
│  └─ Firewall Rules: SSH (IAP), SQL (Admin IP)                   │
└────────────────┬─────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────────┐
│  Compute VM: sql-linux-vm (e2-standard-2, Debian 11)            │
│  ├─ Static IP: 34.57.37.222 (prevent_destroy = true)            │
│  ├─ Persistent Disk: /mnt/sqldata (100GB SSD, auto-reattach)    │
│  ├─ Startup Script: vm-prep.sh.tftpl                            │
│  │  └─ Installs Docker, formats/mounts disk                     │
│  └─ SQL Server 2022 Container (deployed via SSH workflow)       │
│     ├─ Port: 1433                                                │
│     ├─ Data: /var/opt/mssql/data → /mnt/sqldata/data            │
│     ├─ Logs: /var/opt/mssql/log → /mnt/sqldata/log              │
│     └─ Secrets: Password from GCP Secret Manager                │
└──────────────────────────────────────────────────────────────────┘
```

### 🛡️ What Survives VM Destruction?

| Resource | Survives Rebuild? | Cost When VM Destroyed |
|----------|-------------------|------------------------|
| **Static IP** (`google_compute_address.sqlvm_ip`) | ✅ Yes | ~$0.01/hour (~$7/month) |
| **Persistent Disk** (`google_compute_disk.sql_data`) | ✅ Yes | ~$0.17/GB/month (~$17 for 100GB) |
| **SQL Server Data** | ✅ Yes | Included in disk cost |
| **VPC & Firewall** | ✅ Yes | Free |
| **VM Instance** | ❌ No | $0 (destroyed) |
| **Docker Containers** | ❌ No | $0 (redeployed) |

---

## 🚀 Quick Start

### Prerequisites

- **GCP Account** with billing enabled
- **Terraform** 1.7.0 or higher ([Download](https://www.terraform.io/downloads))
- **gcloud CLI** ([Install](https://cloud.google.com/sdk/docs/install))
- **GitHub Repository** with Actions enabled

### 1. Clone & Configure

```bash
# Clone repository
git clone https://github.com/chiranjib555/demo-gcp-terraform.git
cd demo-gcp-terraform

# Create Terraform variables file
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars with your values (project_id, admin_ip_cidr, passwords)
```

### 2. Enable GCP APIs

```bash
gcloud config set project praxis-gantry-475007-k0

gcloud services enable compute.googleapis.com \
  iamcredentials.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  secretmanager.googleapis.com \
  iap.googleapis.com
```

### 3. Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

**Key Terraform Outputs:**
- `sqlvm_external_ip` - Static IP for SQL Server (stays constant)
- `github_actions_sa_email` - Service account for GitHub Actions
- `vm_runtime_sa_email` - Service account for VM (Secret Manager access)

### 4. Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** in your GitHub repository and add:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `GCP_PROJECT_ID` | `praxis-gantry-475007-k0` | Your GCP project ID |
| `GCP_SA_KEY` | `<service-account-json>` | See extraction steps below |
| `SQL_SA_PASSWORD` | Your SA password | From `terraform.tfvars` (keep secret!) |

**Extract Service Account Key (PowerShell):**
```powershell
cd infra

# Get base64-encoded key from Terraform output
terraform output -raw github_actions_sa_key | Out-File -Encoding utf8 sa-key-base64.txt

# Decode to JSON
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content sa-key-base64.txt))) | Out-File sa-key.json

# Copy contents of sa-key.json to GCP_SA_KEY secret
Get-Content sa-key.json | clip  # Copies to clipboard
```

### 5. Grant IAM Permissions

```bash
# Allow GitHub Actions SA to use IAP tunneling
gcloud projects add-iam-policy-binding praxis-gantry-475007-k0 \
  --member="serviceAccount:github-actions-deployer@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"

# Verify service account has required roles
gcloud projects get-iam-policy praxis-gantry-475007-k0 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deployer*"
```

**Required Roles for `github-actions-deployer` SA:**
- ✅ `roles/compute.admin` - Manage VMs
- ✅ `roles/compute.networkAdmin` - Manage VPC/Firewall
- ✅ `roles/compute.securityAdmin` - Firewall rules
- ✅ `roles/iam.serviceAccountAdmin` - Service account management
- ✅ `roles/iam.serviceAccountKeyAdmin` - SA key creation
- ✅ `roles/iap.tunnelResourceAccessor` - SSH via IAP
- ✅ `roles/secretmanager.secretAccessor` - Read SQL passwords

### 6. Install Qodo Merge (Optional)

For AI-powered PR reviews:

1. Visit [Qodo Merge GitHub App](https://github.com/apps/qodo-merge)
2. Click **Install** and select `demo-gcp-terraform` repository
3. Grant required permissions
4. Set repository variable: `QODO_ENABLED=true` (Settings → Variables → Actions)

**Enable automatic reviews:** Set `QODO_ENABLED` variable to `true`  
**Manual reviews only:** Leave `QODO_ENABLED` unset, use `/review` comment or workflow dispatch

---

## 🎮 Usage

### GitHub Actions Workflows

#### 1️⃣ Create VM (`manage-vm-lifecycle.yml`)

**Manual Trigger:**
1. Go to **Actions** tab → **Manage VM Lifecycle**
2. Click **Run workflow**
3. Select action: **`create`**

**What happens:**
- Authenticates with GCP using service account
- Imports existing resources (IP, disk, VPC, firewall) to avoid conflicts
- Runs `terraform apply` to create VM
- VM boots with startup script: installs Docker, mounts persistent disk
- VM ready for SQL Server deployment

**Automatic Trigger:**
- Push to `main` branch with Terraform file changes

#### 2️⃣ Deploy SQL Server (`deploy-sql-startup.yml`)

**Manual Trigger:**
1. Go to **Actions** tab → **Deploy SQL Server to GCP**
2. Click **Run workflow**

**What happens:**
- SSH to VM via IAP tunnel (secure, no public SSH exposure)
- Copies `vm-startup.sh` deployment script to VM
- Executes script which:
  - Authenticates with Secret Manager to fetch SQL SA password
  - Stops and removes any existing SQL Server container
  - Pulls latest SQL Server 2022 image
  - Creates new container with fresh password
  - Mounts persistent disk volumes (`/mnt/sqldata/data`, `/mnt/sqldata/log`)
  - Starts SQL Server on port 1433
- Verifies container is running and checks logs

**Automatic Trigger:**
- Push to `main` branch when `scripts/vm-startup.sh` changes

#### 3️⃣ Destroy VM (`manage-vm-lifecycle.yml`)

**Manual Trigger:**
1. Go to **Actions** tab → **Manage VM Lifecycle**
2. Click **Run workflow**
3. Select action: **`destroy`**

**What happens:**
- Runs `terraform destroy -target=google_compute_instance.sqlvm`
- VM is deleted (**compute charges stop**)
- Static IP remains allocated (small fee ~$7/month)
- Persistent disk remains (data safe, ~$17/month)
- Next `create` action reattaches disk with all data intact

#### 4️⃣ AI PR Reviews (`qodo-merge.yml`)

**Three trigger modes:**

**A) Automatic (on every PR):**
- Requires: `QODO_ENABLED=true` repository variable
- Triggers when PR opened/updated

**B) Comment-based:**
- Comment `/review` on any PR
- Comment `/improve` for code improvement suggestions
- Comment `/describe` for PR description generation
- Comment `/summarize` to summarize PR changes

**C) Manual workflow dispatch:**
1. Go to **Actions** tab → **Qodo Merge PR Review**
2. Click **Run workflow**
3. Enter PR number or URL
4. Select mode: `review`, `improve`, `describe`, or `summarize`

### Local Terraform Operations

#### Check VM Status

```bash
gcloud compute instances describe sql-linux-vm \
  --zone=us-central1-a \
  --format="get(status)"
```

#### SSH to VM (Manual)

```bash
# Via IAP tunnel (recommended)
gcloud compute ssh sql-linux-vm \
  --zone=us-central1-a \
  --tunnel-through-iap

# Check Docker status
sudo docker ps

# View SQL Server logs
sudo docker logs mssql

# Check disk mount
df -h | grep sqldata
```

#### Terraform State Management

```bash
cd infra

# View current state
terraform state list

# Check what would change
terraform plan

# Import existing resource (if needed)
terraform import google_compute_address.sqlvm_ip projects/praxis-gantry-475007-k0/regions/us-central1/addresses/sqlvm-static-ip

# View outputs
terraform output
```

---

## 🔌 Connecting to SQL Server

### Connection Details

**Server Information:**
- **Host:** `34.57.37.222` (Static IP - never changes)
- **Port:** `1433`
- **Authentication:** SQL Server Authentication
- **User:** `sa` (full admin) or `ci_user` (application user)
- **Password:** Stored in GitHub Secrets (`SQL_SA_PASSWORD`)

### Connection Strings

**ADO.NET:**
```csharp
Server=34.57.37.222,1433;Database=master;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=True;
```

**JDBC:**
```java
jdbc:sqlserver://34.57.37.222:1433;databaseName=master;user=sa;password=YOUR_PASSWORD;encrypt=true;trustServerCertificate=true;
```

**PowerShell (SqlClient):**
```powershell
$connectionString = "Server=34.57.37.222,1433;Database=master;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = "SELECT @@VERSION"
$result = $command.ExecuteScalar()
Write-Host $result
$connection.Close()
```

**SQL Server Management Studio (SSMS):**
1. Server type: **Database Engine**
2. Server name: `34.57.37.222,1433`
3. Authentication: **SQL Server Authentication**
4. Login: `sa`
5. Password: `<your-password>`
6. Options → Connection Properties → **Check "Trust server certificate"**

### Test Connection from Command Line

**Using sqlcmd (from VM):**
```bash
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap

# Inside VM
sudo docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P 'YOUR_PASSWORD' \
  -C \
  -Q "SELECT @@VERSION; SELECT name FROM sys.databases;"
```

**Using PowerShell (from local machine):**
```powershell
# Install SqlServer module if not already installed
Install-Module -Name SqlServer -Scope CurrentUser

# Query SQL Server
Invoke-Sqlcmd -ServerInstance "34.57.37.222,1433" `
  -Username "sa" `
  -Password "YOUR_PASSWORD" `
  -Query "SELECT @@VERSION" `
  -TrustServerCertificate
```

### Firewall Access

By default, SQL Server port 1433 is **only accessible from your admin IP** (configured in `terraform.tfvars`).

**Check your current IP:**
```powershell
(Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content
```

**Update allowed IP in Terraform:**
```hcl
# infra/terraform.tfvars
admin_ip_cidr = "YOUR_NEW_IP/32"
```

Then apply changes:
```bash
cd infra
terraform apply -target=google_compute_firewall.allow_sql_1433_admin
```

---

## 📁 Project Structure

```
demo-gcp-terraform/
├── .github/
│   └── workflows/
│       ├── manage-vm-lifecycle.yml      # Create/destroy VM with resource imports
│       ├── deploy-sql-startup.yml       # Deploy SQL Server container via SSH
│       └── qodo-merge.yml               # AI-powered PR reviews
├── infra/
│   ├── providers.tf                     # Terraform & GCP provider config (local state)
│   ├── compute.sql-linux.tf             # VM definition with persistent disk
│   ├── disk.sql-data.tf                 # 100GB SSD persistent disk (survives VM destruction)
│   ├── network.sql-vpc.tf               # VPC network and subnet
│   ├── firewall.sql.tf                  # Firewall rules (SSH from IAP, SQL from admin IP)
│   ├── service-accounts.tf              # Service accounts (github-actions, vm-runtime)
│   ├── secrets.tf                       # GCP Secret Manager (SQL passwords)
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Outputs (IPs, SA emails)
│   ├── terraform.tfvars                 # Your configuration (gitignored)
│   └── scripts/
│       └── vm-prep.sh.tftpl             # VM startup script (Docker install, disk mount)
├── scripts/
│   └── vm-startup.sh                    # SQL Server deployment script (run via SSH)
└── README.md
```

### Key Files Explained

| File | Purpose | Key Features |
|------|---------|--------------|
| **`manage-vm-lifecycle.yml`** | VM create/destroy automation | Imports existing resources before apply to avoid conflicts; supports manual trigger with action selection |
| **`deploy-sql-startup.yml`** | SQL Server deployment | SSH via IAP; copies and executes `vm-startup.sh`; always recreates container with fresh password |
| **`qodo-merge.yml`** | AI code review integration | Three trigger modes (auto/comment/manual); supports PR URL or number input |
| **`compute.sql-linux.tf`** | VM resource definition | e2-standard-2 instance; auto-reattaches persistent disk; service account with cloud-platform scope |
| **`disk.sql-data.tf`** | Persistent storage | 100GB SSD; `prevent_destroy = true`; survives VM deletion |
| **`service-accounts.tf`** | IAM service accounts | `github-actions-deployer` (admin roles); `vm-runtime` (Secret Manager access) |
| **`secrets.tf`** | Password management | Stores SQL SA password in Secret Manager; accessible from VM |
| **`vm-prep.sh.tftpl`** | VM initialization | Installs Docker, formats/mounts disk; runs on VM boot via metadata |
| **`vm-startup.sh`** | SQL deployment script | Deployed via SSH; pulls SQL Server image, configures volumes, starts container |

### Workflow Dependencies

```mermaid
graph TD
    A[Push to main] --> B{File changed?}
    B -->|Terraform files| C[manage-vm-lifecycle.yml]
    B -->|vm-startup.sh| D[deploy-sql-startup.yml]
    B -->|PR opened| E[qodo-merge.yml]
    
    C --> F[terraform apply]
    F --> G[VM created with startup script]
    G --> H[Docker installed, disk mounted]
    H --> I[Ready for SQL deployment]
    
    D --> J[SSH to VM via IAP]
    J --> K[Copy vm-startup.sh]
    K --> L[Execute script]
    L --> M[SQL Server running]
    
    E --> N{Trigger type?}
    N -->|Auto| O[QODO_ENABLED=true]
    N -->|Comment| P[/review command]
    N -->|Manual| Q[workflow_dispatch]
    O --> R[Qodo reviews PR]
    P --> R
    Q --> R
```

---

## 🐛 Troubleshooting

### VM Creation Issues

**Problem:** Terraform fails with "resource already exists"

**Solution:** Workflow automatically imports existing resources. If import fails:
```bash
cd infra

# Manually import stuck resources
terraform import google_compute_address.sqlvm_ip projects/praxis-gantry-475007-k0/regions/us-central1/addresses/sqlvm-static-ip
terraform import google_compute_disk.sql_data projects/praxis-gantry-475007-k0/zones/us-central1-a/disks/sql-data

# Then apply
terraform apply
```

---

**Problem:** Startup script fails (Docker not installing)

**Check serial port logs:**
```bash
gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a | more
```

**Common causes:**
- Line ending issues (CRLF vs LF) - **Solution:** Convert to LF
  ```powershell
  (Get-Content .\infra\scripts\vm-prep.sh.tftpl -Raw) -replace "`r`n", "`n" | Set-Content -NoNewline .\infra\scripts\vm-prep.sh.tftpl
  ```
- Package installation timeout - **Solution:** Check VM internet connectivity
- Disk already formatted - **Solution:** Expected, script detects and skips

---

### SQL Server Deployment Issues

**Problem:** GitHub Actions can't SSH to VM

**Check IAP permissions:**
```bash
gcloud projects get-iam-policy praxis-gantry-475007-k0 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deployer*"
```

**Required roles:**
- ✅ `roles/compute.osLogin`
- ✅ `roles/iap.tunnelResourceAccessor`
- ✅ `roles/compute.viewer`

**Grant missing role:**
```bash
gcloud projects add-iam-policy-binding praxis-gantry-475007-k0 \
  --member="serviceAccount:github-actions-deployer@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

---

**Problem:** SQL Server container fails to start

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
   - **Solution:** Workflow always removes old container before creating new one
   - Check deployment script removes container: `sudo docker rm -f mssql`

---

**Problem:** Can't access Secret Manager from VM

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

### Connection Issues

**Problem:** Can't connect to SQL Server from local machine

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

**Problem:** Connection refused on port 1433

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

---

### Qodo Merge Issues

**Problem:** Qodo bot doesn't respond to `/review` comment

**Check GitHub App installation:**
1. Go to **Settings → Integrations → Applications**
2. Verify **Qodo Merge** is installed
3. Check repository access includes `demo-gcp-terraform`

**Reinstall if needed:**
- Visit https://github.com/apps/qodo-merge
- Click **Configure** → Select repositories

---

**Problem:** Manual workflow dispatch fails (missing PR number)

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

### Terraform State Issues

**Problem:** Terraform state out of sync

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
terraform import google_compute_instance.sqlvm projects/praxis-gantry-475007-k0/zones/us-central1-a/instances/sql-linux-vm
```

---

### Performance Issues

**Problem:** SQL Server slow or unresponsive

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
