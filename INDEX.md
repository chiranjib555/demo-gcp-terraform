# 📚 Documentation Index

Welcome to the **demo-gcp-terraform** project documentation! This index will help you find exactly what you need.

---

## 🚀 Quick Start (New Users)

**Start here if this is your first time:**

1. **[QUICKSTART.md](QUICKSTART.md)** - Step-by-step setup guide
   - Prerequisites
   - Initial deployment
   - GitHub configuration
   - First SQL Server deployment

2. **[NEXT_STEPS.md](NEXT_STEPS.md)** - What to do after setup
   - Testing the infrastructure
   - Daily operations
   - Cost optimization tips

---

## 📖 Main Documentation

### Essential Reading

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[README.md](README.md)** | Complete reference documentation | Understanding the full architecture |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | High-level overview and summary | Getting oriented quickly |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Visual diagrams and flows | Understanding how it all works |

### Setup & Migration

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[QUICKSTART.md](QUICKSTART.md)** | Step-by-step setup guide | First-time setup |
| **[MIGRATION.md](MIGRATION.md)** | Migration from old setup | Upgrading from previous version |
| **[NEXT_STEPS.md](NEXT_STEPS.md)** | Post-setup guide | After initial deployment |

### Operations & Maintenance

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[SCRIPTS.md](SCRIPTS.md)** | Helper scripts documentation | Daily operations |
| **[SIMPLE_MODE.md](SIMPLE_MODE.md)** | Alternative deployment mode | Dev/test environments |

---

## 🛠️ Helper Scripts

**Location:** Root directory (`*.ps1` files)

| Script | Purpose | Usage |
|--------|---------|-------|
| `teardown.ps1` | Destroy VM, keep data | `.\teardown.ps1` |
| `spinup.ps1` | Recreate VM | `.\spinup.ps1` |
| `check-status.ps1` | Check infrastructure status | `.\check-status.ps1` |
| `update-ip.ps1` | Update firewall for new IP | `.\update-ip.ps1` |

**Documentation:** See [SCRIPTS.md](SCRIPTS.md) for details

---

## 📁 Infrastructure Files

**Location:** `infra/` directory

### Core Terraform Files

| File | Purpose | Key Resources |
|------|---------|---------------|
| `providers.tf` | Terraform Cloud + GCP provider | Backend, provider config |
| `variables.tf` | Input variables | disk_size_gb, passwords, etc. |
| `terraform.tfvars` | Variable values (NOT in git!) | Your IP, passwords |
| `outputs.tf` | Output values | IP, disk name, SA email |

### Resource Files

| File | Purpose | Key Resources |
|------|---------|---------------|
| `vpc.tf` | VPC network and subnet | google_compute_network, google_compute_subnetwork |
| `firewall.tf` | Firewall rules | SSH, IAP, SQL port rules |
| `compute.sql-linux.tf` | VM and persistent disk | google_compute_instance, google_compute_disk |
| `github-actions-sa.tf` | Service account for CI/CD | google_service_account, IAM roles |

### Scripts

| File | Purpose | Type |
|------|---------|------|
| `scripts/vm-prep.sh.tftpl` | VM startup script | Bash (templated) |
| `scripts/init-database.sql` | SQL initialization | T-SQL (idempotent) |

---

## ⚙️ GitHub Actions

**Location:** `.github/workflows/`

| File | Purpose | Triggers |
|------|---------|----------|
| `deploy-sql.yml` | Deploy SQL Server container | Manual, push to main, schedule |

**Key features:**
- SSH via IAP tunnel (secure)
- Deploys SQL Server 2022 container
- Runs database initialization
- Idempotent (can run multiple times)

---

## 📚 Documentation by Topic

### Architecture & Design

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Visual diagrams and flows
  - High-level architecture
  - Tear down / spin up flow
  - GitHub Actions deployment flow
  - Data persistence flow
  - Cost comparison
  - Security architecture

- **[README.md](README.md)** - Complete documentation
  - Architecture overview
  - Infrastructure components
  - Cost optimization
  - Security best practices

### Setup & Configuration

- **[QUICKSTART.md](QUICKSTART.md)** - First-time setup
  - Prerequisites
  - Step-by-step instructions
  - GitHub Secrets configuration
  - Verification steps

- **[MIGRATION.md](MIGRATION.md)** - Upgrading from old setup
  - What changed
  - Migration steps
  - Backup procedures
  - Rollback plan

### Operations & Troubleshooting

- **[SCRIPTS.md](SCRIPTS.md)** - Helper scripts
  - PowerShell scripts (Windows)
  - Bash scripts (Linux/Mac)
  - Scheduled automation
  - Usage examples

- **[README.md](README.md#troubleshooting)** - Troubleshooting
  - Common issues
  - Solutions
  - Log locations
  - Support resources

### Alternative Setups

- **[SIMPLE_MODE.md](SIMPLE_MODE.md)** - Direct SSH deployment
  - Setup without IAP tunnel
  - SSH key management
  - Comparison: IAP vs Simple
  - Security considerations

### Cost Optimization

- **[README.md](README.md#cost-optimization)** - Cost analysis
  - Monthly estimates
  - Tear down strategies
  - Usage patterns

- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#cost-breakdown)** - Cost breakdown
  - Always-on vs on-demand
  - Resource costs
  - Savings calculations

---

## 🎯 Find What You Need

### I want to...

#### ...set up the infrastructure for the first time
→ **[QUICKSTART.md](QUICKSTART.md)**

#### ...understand how everything works
→ **[ARCHITECTURE.md](ARCHITECTURE.md)** + **[README.md](README.md)**

#### ...tear down the VM to save costs
→ Run `.\teardown.ps1` (see [SCRIPTS.md](SCRIPTS.md))

#### ...spin up the VM again
→ Run `.\spinup.ps1` then deploy via GitHub Actions

#### ...check the status of my infrastructure
→ Run `.\check-status.ps1`

#### ...update firewall rules for my new IP
→ Run `.\update-ip.ps1`

#### ...deploy SQL Server container
→ **GitHub Actions** → Run workflow: "Deploy SQL Server to GCP"

#### ...troubleshoot issues
→ **[README.md](README.md#troubleshooting)** + `.\check-status.ps1`

#### ...migrate from old setup
→ **[MIGRATION.md](MIGRATION.md)**

#### ...use direct SSH instead of IAP
→ **[SIMPLE_MODE.md](SIMPLE_MODE.md)**

#### ...understand costs
→ **[README.md](README.md#cost-optimization)** + **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#cost-breakdown)**

#### ...back up my database
→ **[README.md](README.md#maintenance)** → Backup Database section

#### ...increase disk size
→ **[NEXT_STEPS.md](NEXT_STEPS.md#maintenance)** → Update terraform.tfvars

#### ...update SQL Server version
→ Edit `.github/workflows/deploy-sql.yml` → Change `SQL_VERSION`

#### ...automate tear down/spin up
→ **[SCRIPTS.md](SCRIPTS.md#scheduled-tear-down-spin-up-optional)**

#### ...connect from my local machine
→ **[README.md](README.md#connection-details)** → Connection String

---

## 📊 Documentation Flow

### For New Users

```
1. QUICKSTART.md
   ↓
2. Deploy infrastructure
   ↓
3. NEXT_STEPS.md
   ↓
4. Test tear down/spin up (SCRIPTS.md)
   ↓
5. ARCHITECTURE.md (understand the details)
   ↓
6. README.md (reference as needed)
```

### For Existing Users Upgrading

```
1. MIGRATION.md
   ↓
2. Backup current data
   ↓
3. Apply infrastructure changes
   ↓
4. Test persistence
   ↓
5. NEXT_STEPS.md (new features)
```

### For Daily Operations

```
Morning:
1. .\spinup.ps1
2. GitHub Actions → Deploy SQL Server
3. Start working

Evening:
1. .\teardown.ps1
2. Save ~$1.50/day

As needed:
- .\check-status.ps1 (status check)
- .\update-ip.ps1 (IP changed)
```

---

## 🔍 Search Index

### Keywords

**Setup:**
- First-time setup → QUICKSTART.md
- Initial deployment → QUICKSTART.md
- Prerequisites → QUICKSTART.md
- GitHub Secrets → QUICKSTART.md

**Operations:**
- Tear down VM → SCRIPTS.md, teardown.ps1
- Spin up VM → SCRIPTS.md, spinup.ps1
- Check status → SCRIPTS.md, check-status.ps1
- Update firewall → SCRIPTS.md, update-ip.ps1
- Deploy SQL Server → GitHub Actions, NEXT_STEPS.md

**Architecture:**
- Persistent disk → ARCHITECTURE.md, README.md
- Static IP → ARCHITECTURE.md, README.md
- IAP tunnel → SIMPLE_MODE.md, README.md
- GitHub Actions → ARCHITECTURE.md, deploy-sql.yml

**Troubleshooting:**
- Connection issues → README.md#troubleshooting
- Startup script failed → README.md#troubleshooting
- GitHub Actions failed → QUICKSTART.md, README.md
- Can't connect to SQL → README.md#troubleshooting

**Cost:**
- Cost optimization → README.md#cost-optimization
- Cost breakdown → PROJECT_SUMMARY.md
- Savings strategies → MIGRATION.md, NEXT_STEPS.md

**Security:**
- Firewall rules → firewall.tf, README.md
- Service account → github-actions-sa.tf
- IAP tunnel → SIMPLE_MODE.md, ARCHITECTURE.md
- Passwords → QUICKSTART.md, terraform.tfvars

---

## 📞 Support

### Documentation Not Clear?

1. Check **[README.md](README.md)** for comprehensive details
2. Check **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** for overview
3. Run `.\check-status.ps1` to diagnose issues

### Still Stuck?

**View logs:**
```powershell
# VM startup logs
gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a

# Docker logs
gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --command "sudo docker logs mssql"

# GitHub Actions logs
# Go to: Actions tab → View workflow run
```

**Common issues:** See **[README.md](README.md#troubleshooting)**

---

## 📝 Document Versions

| Document | Version | Last Updated | Status |
|----------|---------|--------------|--------|
| README.md | 1.0.0 | October 2025 | ✅ Current |
| QUICKSTART.md | 1.0.0 | October 2025 | ✅ Current |
| MIGRATION.md | 1.0.0 | October 2025 | ✅ Current |
| ARCHITECTURE.md | 1.0.0 | October 2025 | ✅ Current |
| PROJECT_SUMMARY.md | 1.0.0 | October 2025 | ✅ Current |
| SIMPLE_MODE.md | 1.0.0 | October 2025 | ✅ Current |
| SCRIPTS.md | 1.0.0 | October 2025 | ✅ Current |
| NEXT_STEPS.md | 1.0.0 | October 2025 | ✅ Current |
| INDEX.md | 1.0.0 | October 2025 | ✅ Current |

---

## 🎯 Success Criteria

You're all set when you've:

- [ ] Read **[QUICKSTART.md](QUICKSTART.md)**
- [ ] Deployed infrastructure successfully
- [ ] Configured GitHub Secrets
- [ ] Deployed SQL Server via GitHub Actions
- [ ] Tested tear down/spin up cycle
- [ ] Verified data persistence
- [ ] Bookmarked this INDEX.md for quick reference

---

**Project:** demo-gcp-terraform  
**Infrastructure:** GCP Compute Engine, Terraform, GitHub Actions, SQL Server 2022  
**Documentation:** Complete and ready to use!

**Happy deploying! 🚀**
