# IAP SSH Configuration Summary

## ✅ Configuration Complete

### VM Configuration (compute.sql-linux.tf)

**Status:** ✅ Already configured

```hcl
metadata = {
  enable-oslogin = "TRUE"  # Required for IAP SSH tunneling
  startup-script = templatefile(...)
}
```

### Service Account IAM Roles (github-actions-sa.tf)

**Status:** ✅ Updated to use `compute.osAdminLogin`

```hcl
# Three required roles for GitHub Actions IAP SSH:

1. roles/compute.osAdminLogin          # SSH via OS Login (UPDATED from osLogin)
2. roles/iap.tunnelResourceAccessor    # Connect via IAP tunnel
3. roles/compute.viewer                # View VM metadata
```

## Key Changes

### Before
- ❌ `roles/compute.osLogin` - Basic OS Login (insufficient for IAP)

### After
- ✅ `roles/compute.osAdminLogin` - Full OS Login with sudo access (required for IAP SSH)

## Why compute.osAdminLogin?

**`roles/compute.osLogin`** - Basic user access
- Can SSH with regular user permissions
- No sudo/root access
- ⚠️ May not work reliably with IAP tunnel + Docker commands

**`roles/compute.osAdminLogin`** - Admin access (recommended)
- Can SSH with admin permissions
- Sudo access granted automatically
- ✅ Works reliably with IAP tunnel
- ✅ Can run Docker commands (required for deployment)

## How It Works

```
GitHub Actions Workflow
  ↓
Authenticate with Service Account Key (GCP_SA_KEY)
  ↓
gcloud compute ssh --tunnel-through-iap
  ↓
IAP Proxy (35.235.240.0/20)
  ↓ Check: iap.tunnelResourceAccessor ✅
  ↓
VM (enable-oslogin = TRUE)
  ↓ Check: compute.osAdminLogin ✅
  ↓
SSH Session Established
  ↓
Run commands: sudo docker exec mssql ...
```

## Testing IAP SSH

### Test from your local machine (after terraform apply)

```bash
# This should work now:
gcloud compute ssh sql-linux-vm \
  --project=praxis-gantry-475007-k0 \
  --zone=us-central1-a \
  --tunnel-through-iap

# If successful, test Docker:
sudo docker ps
```

### GitHub Actions will use the same method

```yaml
gcloud compute ssh sql-linux-vm \
  --project=$GCP_PROJECT_ID \
  --zone=$GCP_ZONE \
  --tunnel-through-iap \
  --command="sudo docker ps"
```

## Apply Changes

```powershell
cd infra
terraform plan   # Review changes
terraform apply  # Apply IAM role update
```

**Expected changes:**
- Update IAM role: `compute.osLogin` → `compute.osAdminLogin`
- No VM changes (already has enable-oslogin = TRUE)

## Verification

After `terraform apply`, verify permissions:

```bash
# Check IAM bindings
gcloud projects get-iam-policy praxis-gantry-475007-k0 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deployer*" \
  --format="table(bindings.role)"
```

**Expected output:**
```
ROLE
roles/compute.osAdminLogin
roles/compute.viewer
roles/iap.tunnelResourceAccessor
```

## Security Note

`compute.osAdminLogin` grants sudo access on the VM. This is appropriate for:
- ✅ Deployment automation (GitHub Actions)
- ✅ Service accounts (not human users)
- ✅ Controlled environment (your project)

If you need more restricted access, consider:
- Using a custom IAM role with specific permissions
- Restricting sudo commands via OS Login policies
- Using separate service accounts for different tasks

## Next Steps

1. ✅ Configuration is complete
2. Run `terraform apply` to update IAM role
3. Test IAP SSH from local machine
4. Run GitHub Actions workflow to deploy SQL Server
5. Verify deployment succeeds

---

**Configuration Status:** ✅ Ready for deployment
