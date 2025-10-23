# Migration to Startup Script Pattern (No SSH)

## Overview
This eliminates all SSH quoting issues by:
1. Storing secrets in **Secret Manager**
2. Uploading SQL file to **GCS bucket**
3. Using **VM startup script** to do all Docker work
4. GitHub Actions only: uploads file → reboots VM

## Prerequisites Setup

### 1. Create GCS Bucket for SQL Files
```bash
gsutil mb -p praxis-gantry-475007-k0 -l us-central1 gs://praxis-sql-bootstrap/
```

### 2. Create Secrets in Secret Manager
```bash
# Store SA password
echo -n 'ChangeMe_Strong#SA_2025!' | gcloud secrets create sql-sa-password \
  --data-file=- \
  --replication-policy=automatic \
  --project=praxis-gantry-475007-k0

# Store CI password
echo -n 'ChangeMe_UseStrongPwd#2025!' | gcloud secrets create sql-ci-password \
  --data-file=- \
  --replication-policy=automatic \
  --project=praxis-gantry-475007-k0
```

### 3. Create/Verify Service Account for VM
```bash
# Create SA (if doesn't exist)
gcloud iam service-accounts create sql-vm-sa \
  --display-name="SQL VM Service Account" \
  --project=praxis-gantry-475007-k0

# Grant Secret Manager access
gcloud secrets add-iam-policy-binding sql-sa-password \
  --member="serviceAccount:sql-vm-sa@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=praxis-gantry-475007-k0

gcloud secrets add-iam-policy-binding sql-ci-password \
  --member="serviceAccount:sql-vm-sa@praxis-gantry-475007-k0.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=praxis-gantry-475007-k0

# Grant GCS read access
gsutil iam ch \
  serviceAccount:sql-vm-sa@praxis-gantry-475007-k0.iam.gserviceaccount.com:objectViewer \
  gs://praxis-sql-bootstrap

# Attach SA to VM
gcloud compute instances set-service-account sql-linux-vm \
  --service-account=sql-vm-sa@praxis-gantry-475007-k0.iam.gserviceaccount.com \
  --scopes=cloud-platform \
  --zone=us-central1-a \
  --project=praxis-gantry-475007-k0
```

### 4. Add Startup Script to VM Metadata
The startup script is in `scripts/vm-startup.sh`. Upload it:

```bash
gcloud compute instances add-metadata sql-linux-vm \
  --zone=us-central1-a \
  --metadata-from-file startup-script=scripts/vm-startup.sh \
  --project=praxis-gantry-475007-k0
```

## GitHub Actions Changes

The workflow becomes **dramatically simpler**:
1. Upload `init-database.sql` to GCS
2. Reset VM (triggers startup script)
3. Wait for VM to be ready
4. Done!

No SSH, no quoting, no command substitution issues.

## Testing

### Local Test (upload SQL file manually)
```bash
gsutil cp infra/scripts/init-database.sql gs://praxis-sql-bootstrap/init-database.sql

# Trigger startup script by resetting
gcloud compute instances reset sql-linux-vm \
  --zone=us-central1-a \
  --project=praxis-gantry-475007-k0

# Watch logs
gcloud compute instances get-serial-port-output sql-linux-vm \
  --zone=us-central1-a \
  --project=praxis-gantry-475007-k0 \
  | grep -A 50 "startup-script"
```

## Rollback Plan

If this doesn't work, you can:
1. Remove the startup-script metadata
2. Revert to SSH-based workflow
3. Secrets remain in Secret Manager (no cost to keep them)

## Cost Estimate

- **Secret Manager**: $0.06/month per secret × 2 = $0.12/month
- **GCS Storage**: ~$0.02/month for 1GB
- **Total**: ~$0.15/month additional cost
