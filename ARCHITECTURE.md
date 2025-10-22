# Infrastructure Architecture Diagrams

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GitHub Actions (CI/CD)                          │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Workflow: deploy-sql.yml                                         │ │
│  │  ├─ Trigger: Manual, Push to main, or Schedule                    │ │
│  │  ├─ Auth: Service Account Key (GCP_SA_KEY secret)                 │ │
│  │  ├─ Connect: IAP Tunnel (secure, no public SSH)                   │ │
│  │  └─ Deploy: SQL Server 2022 container + init scripts              │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ IAP Tunnel (35.235.240.0/20)
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       Google Cloud Platform (GCP)                       │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  VPC Network: demo-vpc                                            │ │
│  │  └─ Subnet: 10.10.0.0/24 (us-central1-a)                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Firewall Rules                                                   │ │
│  │  ├─ allow-ssh-admin: Port 22 from YOUR_IP                         │ │
│  │  ├─ allow-iap-ssh: Port 22 from IAP range                         │ │
│  │  └─ allow-sql-1433-admin: Port 1433 from YOUR_IP                  │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Static IP: 34.57.37.222 (PROTECTED)                              │ │
│  │  └─ lifecycle { prevent_destroy = true }                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Compute VM: sql-linux-vm                                         │ │
│  │  ├─ Machine: e2-standard-2 (2 vCPU, 8 GB RAM)                     │ │
│  │  ├─ OS: Debian 11                                                 │ │
│  │  ├─ Boot Disk: 50 GB                                              │ │
│  │  ├─ Attached Disk: sql-data-disk (auto-attach)                    │ │
│  │  ├─ Startup: vm-prep.sh.tftpl (Docker + mount disk)               │ │
│  │  └─ Tags: sql, ssh                                                │ │
│  │                                                                    │ │
│  │  Inside VM:                                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │  Docker Container: mssql                                      │ │ │
│  │  │  ├─ Image: mcr.microsoft.com/mssql/server:2022-latest         │ │ │
│  │  │  ├─ Port: 1433 → 1433                                         │ │ │
│  │  │  ├─ Volumes:                                                  │ │ │
│  │  │  │  ├─ /mnt/sqldata/data → /var/opt/mssql/data               │ │ │
│  │  │  │  ├─ /mnt/sqldata/log → /var/opt/mssql/log                 │ │ │
│  │  │  │  └─ /mnt/sqldata/secrets → /var/opt/mssql/secrets         │ │ │
│  │  │  └─ Restart: unless-stopped                                  │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Persistent Disk: sql-data-disk (PROTECTED)                       │ │
│  │  ├─ Type: pd-ssd (SSD for better performance)                     │ │
│  │  ├─ Size: 100 GB                                                  │ │
│  │  ├─ Mount: /mnt/sqldata                                           │ │
│  │  ├─ Contains: All SQL Server databases and logs                   │ │
│  │  ├─ lifecycle { prevent_destroy = true }                          │ │
│  │  └─ Survives: VM deletion and recreation                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Service Account: github-actions-deployer                         │ │
│  │  ├─ roles/compute.osLogin                                         │ │
│  │  ├─ roles/iap.tunnelResourceAccessor                              │ │
│  │  └─ roles/compute.viewer                                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                             │ SQL Connection
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Your Local Machine                              │
│  ├─ Connection String:                                                 │
│  │  Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;...       │
│  ├─ Tools: SSMS, Azure Data Studio, sqlcmd, PowerShell                 │
│  └─ Helper Scripts: teardown.ps1, spinup.ps1, check-status.ps1         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Tear Down / Spin Up Flow

### Tear Down Flow

```
┌─────────────────┐
│  .\teardown.ps1 │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  terraform destroy                   │
│  -target=google_compute_instance.sqlvm│
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  VM Destroyed                        │
│  ├─ Compute stopped ✅               │
│  ├─ Cost reduced ✅                  │
│  └─ Billing: ~$24/month              │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  What Remains?                       │
│  ├─ Static IP (34.57.37.222) ✅      │
│  ├─ Persistent Disk (100GB) ✅       │
│  ├─ All SQL Server Data ✅           │
│  └─ VPC & Firewall Rules ✅          │
└──────────────────────────────────────┘
```

### Spin Up Flow

```
┌─────────────────┐
│  .\spinup.ps1   │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  terraform apply                     │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  VM Created                          │
│  ├─ Same Static IP ✅                │
│  ├─ Disk Auto-Attached ✅            │
│  └─ Startup Script Runs              │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Startup Script (vm-prep.sh.tftpl)  │
│  ├─ Install Docker                   │
│  ├─ Mount /mnt/sqldata               │
│  └─ Set Permissions                  │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  VM Ready (Wait ~2 minutes)          │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  GitHub Actions: Deploy SQL Server   │
│  (Manual or Automatic)               │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  GitHub Actions Workflow             │
│  ├─ SSH via IAP                      │
│  ├─ Deploy SQL Server Container      │
│  ├─ Run init-database.sql            │
│  └─ Verify Deployment                │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  SQL Server Running ✅               │
│  ├─ Database: DemoDB                 │
│  ├─ User: ci_user                    │
│  ├─ Data: Fully Restored             │
│  └─ Ready for Connections!           │
└──────────────────────────────────────┘
```

---

## GitHub Actions Deployment Flow

```
┌─────────────────────────────────────────┐
│  Trigger                                │
│  ├─ Manual (Actions UI)                 │
│  ├─ Push to main                        │
│  └─ Schedule (optional)                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Authenticate to GCP                    │
│  └─ Use GCP_SA_KEY secret               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  SSH via IAP Tunnel                     │
│  gcloud compute ssh --tunnel-through-iap│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Stop Old Container (if exists)         │
│  sudo docker stop mssql                 │
│  sudo docker rm mssql                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Deploy New Container                   │
│  sudo docker run -d \                   │
│    --name mssql \                       │
│    -e MSSQL_SA_PASSWORD=... \           │
│    -p 1433:1433 \                       │
│    -v /mnt/sqldata/data:... \           │
│    mcr.microsoft.com/mssql/server:2022  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Wait for SQL Server                    │
│  (Max 60 seconds, check every 5s)       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Copy init-database.sql to VM           │
│  gcloud compute scp --tunnel-through-iap│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Run Initialization Script              │
│  sudo docker exec mssql sqlcmd \        │
│    -i init-database.sql                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Verify Deployment                      │
│  └─ Query: SELECT name FROM sys.databases│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Cleanup                                │
│  └─ Remove temporary files              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Success! ✅                            │
│  SQL Server running on VM               │
└─────────────────────────────────────────┘
```

---

## Data Persistence Flow

```
┌─────────────────────────────────────────┐
│  Initial Deployment                     │
│  └─ Create tables, insert data          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Data Stored On Persistent Disk         │
│  /mnt/sqldata/data/*.mdf                │
│  /mnt/sqldata/log/*.ldf                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Tear Down VM                           │
│  terraform destroy -target=...sqlvm     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  VM Destroyed ❌                        │
│  SQL Server Container Gone ❌           │
│  BUT...                                 │
│  Persistent Disk Still Exists ✅        │
│  All Data Files Safe ✅                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Spin Up VM                             │
│  terraform apply                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  New VM Created ✅                      │
│  Disk Auto-Attached to /mnt/sqldata ✅  │
│  Data Files Still There ✅              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Deploy SQL Server Container            │
│  (via GitHub Actions)                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  SQL Server Reads Existing Data ✅      │
│  ├─ Databases: Attached automatically   │
│  ├─ Tables: Still there                 │
│  ├─ Data: Unchanged                     │
│  └─ Indexes: Intact                     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Verify Data Persistence                │
│  └─ SELECT * FROM TestTable             │
│     → All rows present! ✅              │
└─────────────────────────────────────────┘
```

---

## Cost Comparison Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Scenario 1: Always-On (Old Approach)                      │
├─────────────────────────────────────────────────────────────┤
│  VM: ████████████████████████████████████████  $49/month   │
│  Disk: ████████  $8/month                                   │
│  ───────────────────────────────────────────────────────    │
│  Total: $57/month                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Scenario 2: Work Hours (8 AM-6 PM, M-F)                   │
├─────────────────────────────────────────────────────────────┤
│  VM: ███████████  $13/month                                 │
│  Disk: █████████████████  $17/month                         │
│  IP: ███████  $7/month                                      │
│  ───────────────────────────────────────────────────────    │
│  Total: $37/month                                           │
│  Savings: $20/month (35%) ✅                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Scenario 3: On-Demand (Tear Down When Not Used)           │
├─────────────────────────────────────────────────────────────┤
│  VM: (destroyed)  $0/month                                  │
│  Disk: █████████████████  $17/month                         │
│  IP: ███████  $7/month                                      │
│  ───────────────────────────────────────────────────────    │
│  Total: $24/month                                           │
│  Savings: $33/month (58%) ✅✅                              │
└─────────────────────────────────────────────────────────────┘

Key Insight:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Persistent disk + static IP cost ~$24/month ALWAYS.
VM compute cost varies based on uptime.
Tear down when not in use → save $1.50/day!
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Internet                                                   │
└──────────────┬──────────────────────────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
      ▼                 ▼
┌──────────┐    ┌─────────────────┐
│ Your IP  │    │  Google IAP     │
│ (Admin)  │    │  35.235.240.0/20│
└────┬─────┘    └────────┬────────┘
     │                   │
     │ Firewall Rules:   │
     │ ├─ SSH (22) ✅   │ SSH (22) ✅
     │ └─ SQL (1433) ✅ │ SQL (1433) ❌
     │                   │
     └─────────┬─────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│  GCP VPC Network (demo-vpc)                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Compute VM (sql-linux-vm)                             │  │
│  │  ├─ OS Login: ENABLED ✅                               │  │
│  │  ├─ Public IP: 34.57.37.222                            │  │
│  │  └─ Private IP: 10.10.0.x                              │  │
│  │                                                         │  │
│  │  Security:                                              │  │
│  │  ├─ SSH access: Your IP OR IAP only                    │  │
│  │  ├─ SQL access: Your IP only                           │  │
│  │  ├─ No RDP (not Windows)                               │  │
│  │  └─ Service account: minimal permissions               │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

Service Account Permissions:
┌──────────────────────────────────────────────────────────────┐
│  github-actions-deployer@...                                 │
│  ├─ roles/compute.osLogin                                    │
│  │  └─ Allows: SSH via OS Login                             │
│  ├─ roles/iap.tunnelResourceAccessor                         │
│  │  └─ Allows: Connect via IAP tunnel                       │
│  └─ roles/compute.viewer                                     │
│     └─ Allows: Read VM metadata                              │
└──────────────────────────────────────────────────────────────┘
```

---

## File Structure Tree

```
demo-gcp-terraform/
├── infra/
│   ├── providers.tf              # Terraform Cloud backend + GCP provider
│   ├── variables.tf              # Input variables (disk_size_gb, passwords, etc.)
│   ├── terraform.tfvars          # Variable values (NOT in git!)
│   ├── vpc.tf                    # VPC network and subnet
│   ├── firewall.tf               # Firewall rules (SSH, IAP, SQL)
│   ├── compute.sql-linux.tf      # VM + persistent disk + lifecycle protection
│   ├── github-actions-sa.tf      # Service account for CI/CD
│   ├── outputs.tf                # Outputs (IP, disk name, SA email, etc.)
│   └── scripts/
│       ├── vm-prep.sh.tftpl      # Minimal startup script (Docker + mount)
│       └── init-database.sql     # SQL initialization (idempotent)
│
├── .github/
│   └── workflows/
│       └── deploy-sql.yml        # GitHub Actions deployment workflow
│
├── teardown.ps1                  # Helper: Destroy VM (keep data)
├── spinup.ps1                    # Helper: Recreate VM
├── check-status.ps1              # Helper: Check infrastructure status
├── update-ip.ps1                 # Helper: Update firewall for new IP
│
├── README.md                     # Complete documentation
├── QUICKSTART.md                 # Step-by-step setup guide
├── MIGRATION.md                  # Migration from old setup
├── SIMPLE_MODE.md                # Alternative: Direct SSH deployment
├── SCRIPTS.md                    # Helper scripts documentation
├── NEXT_STEPS.md                 # Post-setup guide
├── PROJECT_SUMMARY.md            # Project overview and summary
└── ARCHITECTURE.md               # This file (architecture diagrams)
```

---

## Resource Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Terraform Resources                                        │
└─────────────────────────────────────────────────────────────┘

Protected Resources (prevent_destroy = true):
┌──────────────────────┐  ┌──────────────────────┐
│  Static IP           │  │  Persistent Disk     │
│  sqlvm-ip            │  │  sql-data-disk       │
│  ────────────────    │  │  ────────────────    │
│  Status: ALWAYS      │  │  Status: ALWAYS      │
│  Cost: $7/month      │  │  Cost: $17/month     │
│  Survives: ✅ ALL    │  │  Survives: ✅ ALL    │
└──────────────────────┘  └──────────────────────┘

Ephemeral Resources (can be destroyed):
┌──────────────────────┐  ┌──────────────────────┐
│  Compute VM          │  │  Docker Container    │
│  sql-linux-vm        │  │  mssql               │
│  ────────────────    │  │  ────────────────    │
│  Status: On-Demand   │  │  Status: Deployed    │
│  Cost: $0 or $49/mo  │  │  Cost: Included      │
│  Survives: ❌ Tear   │  │  Survives: ❌ Redeploy│
└──────────────────────┘  └──────────────────────┘

Persistent Resources (never destroyed):
┌──────────────────────┐  ┌──────────────────────┐
│  VPC Network         │  │  Firewall Rules      │
│  demo-vpc            │  │  allow-ssh, etc.     │
│  ────────────────    │  │  ────────────────    │
│  Status: ALWAYS      │  │  Status: ALWAYS      │
│  Cost: Free          │  │  Cost: Free          │
│  Survives: ✅ ALL    │  │  Survives: ✅ ALL    │
└──────────────────────┘  └──────────────────────┘
```

---

**Legend:**
- ✅ Resource exists / Protected / Successful
- ❌ Resource destroyed / Not protected / Failed
- ⚠️ Warning / Caution needed
- 🔒 Security-related
- 💾 Data storage
- 🌐 Network-related
- 🐳 Container-related
- 🤖 Automation-related
