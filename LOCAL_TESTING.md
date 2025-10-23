# Local Testing Guide

This guide explains how to test the SQL Server deployment locally before pushing to GitHub.

## Prerequisites

1. **gcloud CLI** installed and authenticated
2. **Required IAM permissions** on your GCP project:
   - `compute.instances.get`
   - `compute.instances.use`
   - `iap.tunnelResourceAccessor`
3. **Secrets ready**:
   - SQL SA password
   - CI user password

## Testing on Linux/macOS/WSL (Bash)

### 1. Make the script executable:

```bash
chmod +x test-deploy-local.sh
```

### 2. Run the test with your secrets:

```bash
SA_PWD='YourSAPassword123!' \
CI_PASSWORD='YourCiPassword456!' \
./test-deploy-local.sh
```

### 3. Optional: Override defaults:

```bash
GCP_PROJECT='your-project-id' \
GCP_ZONE='us-central1-a' \
VM_NAME='sql-linux-vm' \
SA_PWD='YourSAPassword123!' \
CI_PASSWORD='YourCiPassword456!' \
DB_NAME='DemoDB' \
./test-deploy-local.sh
```

## Testing on Windows (PowerShell)

### Run from PowerShell:

```powershell
.\test-deploy-local.ps1 `
  -SaPassword "YourSAPassword123!" `
  -CiPassword "YourCiPassword456!"
```

### With custom parameters:

```powershell
.\test-deploy-local.ps1 `
  -GcpProject "your-project-id" `
  -GcpZone "us-central1-a" `
  -VmName "sql-linux-vm" `
  -SaPassword "YourSAPassword123!" `
  -CiPassword "YourCiPassword456!" `
  -DbName "DemoDB"
```

## What the Test Does

The local test script performs the same steps as the GitHub Actions workflow:

1. ✓ **Configure gcloud** - Sets project and zone
2. ✓ **Test SSH** - Verifies IAP tunnel connectivity
3. ✓ **Copy script** - Uploads `provision_sql.sh` to VM
4. ✓ **Run provision** - Executes deployment on VM
5. ✓ **Verify** - Checks container, SQL Server, database, and user

## Understanding the Output

### Successful Run:
```
=== Local SQL Deployment Test ===
✓ Configuration validated
[Step 1/5] Configuring gcloud...
✓ Authenticated as: you@example.com
[Step 2/5] Testing SSH connection to VM...
✓ SSH connection working
[Step 3/5] Copying provision script to VM...
✓ Script copied successfully
[Step 4/5] Running provision script on VM...
[provision] Data dir: /mnt/sqldata
[provision] Pulling image...
[provision] Starting container...
[provision] Waiting up to 5 minutes for SQL to be ready...
[provision] SQL responds to queries.
[provision] Ensuring DB 'DemoDB' and login 'ci_user'...
[provision] Done.
✓ Provision script completed successfully
[Step 5/5] Verifying deployment...
  Container status: Up 2 minutes (healthy)
✓ SQL Server responding
✓ Database 'DemoDB' exists

╔════════════════════════════════════════════╗
║   ✓ Deployment Test Successful!           ║
╚════════════════════════════════════════════╝

Connection details:
  Server: 34.57.37.222,1433
  Database: DemoDB
  User: ci_user
```

### If Something Fails:

The script will:
- Show which step failed
- Display container logs for debugging
- List files in `/mnt/sqldata`
- Exit with error code 1

## Troubleshooting

### SSH Connection Fails
```
✗ SSH connection failed
```
**Fix:** 
- Ensure IAP tunnel is allowed in firewall
- Check your IAM permissions
- Verify VM is running: `gcloud compute instances list`

### Container Not Starting
```
✗ SQL Server not responding
```
**Fix:**
- Check logs: The script automatically shows them on failure
- Common issues:
  - Weak SA password (needs uppercase, lowercase, numbers, special chars)
  - Insufficient disk space
  - Port 1433 already in use

### Database/User Not Created
```
✗ Database 'DemoDB' not found
```
**Fix:**
- Check if SQL Server is fully initialized
- Verify SA password is correct
- Check SQL logs for permission issues

## After Successful Local Test

Once your local test passes:

1. **Commit your changes** (if any):
   ```bash
   git add scripts/provision_sql.sh
   git commit -m "Update provision script"
   git push origin main
   ```

2. **Run GitHub Actions workflow**:
   - Go to Actions tab in GitHub
   - Select "Deploy or Manage SQL Server Container"
   - Click "Run workflow"
   - Watch it succeed with the same logic! 🎉

3. **Connect from your SQL client**:
   ```
   Server: 34.57.37.222,1433
   Database: DemoDB
   User: ci_user
   Password: (your CI_PASSWORD)
   ```

## Security Notes

⚠️ **Never commit passwords to git!**
- Keep secrets in environment variables
- Use GitHub Secrets for CI/CD
- Don't echo passwords in logs

✅ **These test scripts:**
- Only pass secrets via environment variables
- Use secure SSH tunnels (IAP)
- Don't store secrets on disk

## Files in This Project

- `scripts/provision_sql.sh` - Main deployment script (runs on VM)
- `test-deploy-local.sh` - Bash test runner (Linux/macOS/WSL)
- `test-deploy-local.ps1` - PowerShell test runner (Windows)
- `.github/workflows/deploy-sql.yml` - GitHub Actions workflow

All three use the same `provision_sql.sh` script, ensuring consistency between local tests and CI/CD.
