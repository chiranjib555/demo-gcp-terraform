# Change Log

All notable changes to this project will be documented in this file.

## [2.0.0] - November 2, 2025

### ✅ Fully Operational SQL Server Infrastructure

**Major Accomplishments:**
- ✅ **VM Created**: `sql-linux-vm` (e2-standard-2, Debian 11) running in us-central1-a
- ✅ **Static IP Allocated**: Persistent IP (stable across VM rebuilds)
- ✅ **Persistent Storage**: 100GB SSD mounted at `/mnt/sqldata` with proper subdirectory structure
- ✅ **SQL Server 2022**: Developer Edition running in Docker container
- ✅ **Database Created**: DemoDB with sample schema and data
- ✅ **Users Configured**: SA (admin) + ci_user (application user with db_owner)
- ✅ **SSMS Connection**: Successfully connected from Windows 11 laptop

### 📊 Sample Database Schema

**DemoDB** includes the following tables:

| Table | Records | Description |
|-------|---------|-------------|
| **Customers** | 5 | Customer master data (ID, Name, Email, Phone) |
| **Products** | 10 | Product catalog (ID, Name, Category, Price, Stock) |
| **Orders** | 5 | Order headers (ID, CustomerID, Date, Total) |
| **OrderDetails** | 15 | Order line items (OrderID, ProductID, Quantity, Price) |

**Sample Data Includes:**
- Technology products: Laptop, Smartphone, Tablet, Monitor, Keyboard, etc.
- Customer orders with line items and totals
- Full referential integrity (foreign keys configured)

### 🔧 Issues Resolved

1. **✅ Git Branch Synchronization**: Resolved merge conflicts and synchronized with origin/main
2. **✅ GitHub Actions Workflows**: Fixed and verified both VM lifecycle and SQL deployment workflows
3. **✅ Service Account Keys**: Properly extracted and configured GCP_SA_KEY for GitHub Actions
4. **✅ SQL Server Path Issues**: Updated sqlcmd path from `/opt/mssql-tools` to `/opt/mssql-tools18/bin/sqlcmd`
5. **✅ Persistent Storage**: Implemented correct subdirectory structure `/mnt/sqldata/mssql/{data,log,secrets}`
6. **✅ Script Consistency**: Aligned `vm-prep.sh.tftpl` and `vm-startup.sh` for consistent paths
7. **✅ Qodo Merge Integration**: Fixed workflow context issues (env vs vars)
8. **✅ Database Initialization**: Deployed init-database.sql via startup workflow
9. **✅ User Permissions**: Granted ci_user db_owner role on DemoDB
10. **✅ SSMS Connectivity**: Verified external access from Windows laptop

### 🎯 Validated Features

| Feature | Status | Verification Method |
|---------|--------|---------------------|
| **VM Creation** | ✅ Working | GitHub Actions workflow executed successfully |
| **Persistent Disk Mount** | ✅ Working | Verified `/mnt/sqldata` mount and subdirectories |
| **SQL Server Container** | ✅ Running | `docker ps` shows mssql container active |
| **Database Files on Disk** | ✅ Confirmed | Checked `/mnt/sqldata/mssql/data/DemoDB.mdf` exists |
| **User Authentication** | ✅ Working | Connected with ci_user credentials |
| **Sample Data** | ✅ Populated | Queried Customers, Products, Orders tables |
| **External Access** | ✅ Working | SSMS connection from Windows 11 successful |
| **Firewall Rules** | ✅ Configured | SQL port 1433 accessible from admin IP |
| **IAP SSH Access** | ✅ Working | GitHub Actions can SSH via IAP tunnel |
| **Secret Manager** | ✅ Integrated | Passwords retrieved from GCP secrets |

### 📝 Workflow Testing Results

**Workflow 1: Manage VM Lifecycle (Create/Destroy)** ✅
- Create action: Successfully provisions VM with all resources
- Persistent resources preserved: Static IP, persistent disk, VPC, firewall
- Destroy action: Removes VM, keeps persistent resources intact

**Workflow 2: Deploy SQL Server (Startup Script Pattern)** ✅
- SSH via IAP: Connection successful
- Script execution: vm-startup.sh runs without errors
- Container deployment: SQL Server 2022 starts successfully
- Database initialization: init-database.sql executed
- User creation: ci_user created with proper permissions

**Workflow 3: Qodo Merge (AI PR Reviews)** ✅
- Manual trigger: Works with PR number or URL
- Comment trigger: Responds to `/review` commands
- Auto trigger: Configurable via QODO_ENABLED variable
- Context issues: Resolved (moved env to job level, use vars in if condition)

### 🎓 Lessons Learned

1. **SQL Server 2022 Tools**: Uses `/opt/mssql-tools18` (not `mssql-tools`), requires `-C` flag for trust server certificate
2. **Persistent Storage Structure**: Must create `/mnt/sqldata/mssql/` subdirectories for proper separation
3. **Docker Volume Mounts**: Explicit volume mappings ensure data persists on external disk
4. **GitHub Actions Context**: `env` cannot be used in job-level `if`, use `vars` instead
5. **Branch Protection**: Requires PR workflow for all changes (good practice enforced)
6. **Password Complexity**: SQL Server requires strong passwords (uppercase, lowercase, digit, special char)
7. **Service Account Scopes**: VM needs `cloud-platform` scope for Secret Manager access
8. **IAP Permissions**: GitHub Actions SA needs `roles/iap.tunnelResourceAccessor` for SSH

### Added
- Implemented persistent storage with proper subdirectory structure (`/mnt/sqldata/mssql/{data,log,secrets}`)
- Created DemoDB sample database with relational schema (Customers, Products, Orders, OrderDetails)
- Added ci_user with db_owner permissions for application access
- Integrated GCP Secret Manager for password management

### Fixed
- Updated sqlcmd path from `/opt/mssql-tools` to `/opt/mssql-tools18/bin/sqlcmd` for SQL Server 2022
- Aligned `vm-prep.sh.tftpl` and `vm-startup.sh` scripts for consistent directory structure
- Fixed Qodo Merge workflow context issues (moved env to job level, use vars in if conditions)
- Resolved git merge conflicts and synchronized branches
- Fixed service account key extraction for GitHub Actions

### Changed
- Migrated from single startup script to two-workflow design (VM lifecycle + SQL deployment)
- Updated Docker volume mounts to use persistent disk subdirectories
- Enhanced GitHub Actions workflows with better error handling and logging

### Verified
- End-to-end deployment workflow (VM creation → SQL deployment → database initialization)
- SSMS connectivity from external Windows laptop
- Data persistence on separate disk (survives VM destruction)
- IAP SSH access from GitHub Actions
- Firewall rules and static IP configuration

---

## [1.0.0] - Initial Release

### Added
- Initial Terraform infrastructure setup
  - Compute VM (e2-standard-2, Debian 11)
  - VPC network and firewall rules
  - Static IP address
  - Persistent SSD disk (100GB)
- GitHub Actions workflow for VM lifecycle management
- SQL Server 2022 containerized deployment
- Service accounts with IAM roles
  - github-actions-deployer (Terraform + SSH)
  - vm-runtime (Secret Manager access)
- Basic networking configuration
  - SSH via IAP tunnel
  - SQL Server port 1433 (restricted to admin IP)
- Docker-based SQL Server 2022 deployment
- VM startup script (`vm-prep.sh.tftpl`)
  - Docker installation
  - Persistent disk mounting

### Infrastructure Components
- **VM**: sql-linux-vm (e2-standard-2)
- **Disk**: sql-data (100GB SSD, pd-ssd)
- **Network**: sql-vpc (custom VPC)
- **IP**: Static external IP with `prevent_destroy`
- **Firewall**: SSH (IAP), SQL (admin IP only)

---

## Release Notes Format

This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) principles.

### Version Format
- **Major.Minor.Patch** (Semantic Versioning)
- Major: Breaking changes or significant architecture updates
- Minor: New features, backward-compatible
- Patch: Bug fixes, small improvements

### Categories
- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
