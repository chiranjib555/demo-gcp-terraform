# Decision: Migration to Startup Script Pattern

## Executive Summary

**Recommendation: Option A - Startup Script + Secret Manager** ✅

This eliminates ALL SSH quoting issues by moving the work to GCP-native mechanisms.

## Why This is Best for Your Use Case

### Current Problem
- SSH command quoting through GitHub Actions is extremely fragile
- Multiple layers: YAML → Bash → gcloud → SSH → remote bash → docker
- Special characters in passwords cause "syntax error near unexpected token '('"
- Go templates `{{...}}` conflict with GitHub Actions syntax
- Maintenance nightmare - every change risks breaking quoting

### How Startup Script Solves This

```
┌─────────────────────────────────────────────────────────┐
│ BEFORE (SSH Hell)                                       │
├─────────────────────────────────────────────────────────┤
│ GitHub Actions                                          │
│   ↓ (escape quotes, escape special chars)              │
│ gcloud compute ssh --command "..."                      │
│   ↓ (SSH layer, more escaping)                         │
│ VM receives mangled command                             │
│   ↓ (syntax errors, quote mismatches)                  │
│ ❌ Failure                                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ AFTER (Startup Script)                                  │
├─────────────────────────────────────────────────────────┤
│ GitHub Actions                                          │
│   ↓ (simple: upload file to GCS)                       │
│ GCS Bucket (init-database.sql)                          │
│   ↓                                                     │
│ GitHub Actions: reset VM                                │
│   ↓                                                     │
│ VM boots → startup script runs                          │
│   ↓ (fetches secrets from Secret Manager)              │
│   ↓ (downloads SQL from GCS)                           │
│   ↓ (runs Docker commands natively)                    │
│ ✅ Success                                              │
└─────────────────────────────────────────────────────────┘
```

## Comparison with Other Options

| Feature | Option A (Startup Script) | Option B (COS) | Option C (OS Config) |
|---------|---------------------------|----------------|---------------------|
| **Complexity** | ⭐ Low | ⭐⭐ Medium | ⭐⭐⭐ High |
| **Works with current VM** | ✅ Yes | ❌ Need COS image | ✅ Yes |
| **SSH needed** | ❌ No | ❌ No | ❌ No |
| **Learning curve** | Low | Medium | High |
| **Reboot required** | ✅ Yes (acceptable) | ✅ Yes | ❌ No |
| **Best for** | Your case! | High-scale prod | Enterprise fleets |

## Migration Plan

### Phase 1: Setup (One-time, ~15 minutes)
1. Create GCS bucket for SQL files
2. Create secrets in Secret Manager (SA password, CI password)
3. Create/configure service account for VM
4. Attach service account to VM
5. Add startup script to VM metadata

**Files created:**
- ✅ `scripts/vm-startup.sh` - The startup script
- ✅ `.github/workflows/deploy-sql-startup.yml` - New workflow
- ✅ `MIGRATION_TO_STARTUP_SCRIPT.md` - Setup instructions

### Phase 2: Test (5 minutes)
1. Manually upload SQL file to GCS
2. Reset VM to trigger startup script
3. Verify container starts and database initializes
4. Check serial logs for any issues

### Phase 3: Deploy (2 minutes)
1. Commit and push the new files
2. Run the new GitHub workflow
3. Verify deployment

### Phase 4: Cleanup (Optional)
- Archive old workflow: `.github/workflows/deploy-sql.yml`
- Remove `test-deploy-local.ps1` and related files
- Update documentation

## What Gets Better

### GitHub Actions Workflow
**Before:** 185 lines with complex nested quoting  
**After:** 120 lines, 95% of which is just waiting/logging

**Before:**
```yaml
--command "sudo docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P \"$SA_PASSWORD\" -C -b \
  -v CI_PASSWORD=\"$CI_PASSWORD\" \
  -v VERSION=\"\$(date +%Y%m%d-%H%M%S)\" \
  -i /tmp/init-database.sql"
```

**After:**
```yaml
gsutil cp infra/scripts/init-database.sql gs://praxis-sql-bootstrap/
gcloud compute instances reset sql-linux-vm --zone us-central1-a
```

### Secrets Management
**Before:** In GitHub Secrets → passed through SSH → bash → docker  
**After:** In Secret Manager → fetched directly by VM (never leaves GCP)

### Debugging
**Before:** Check GitHub Actions logs → SSH manually → check container  
**After:** Check serial port output → all logs in one place

## Cost Analysis

| Item | Monthly Cost |
|------|--------------|
| Secret Manager (2 secrets) | $0.12 |
| GCS storage (< 1 MB) | $0.00 |
| Extra API calls | $0.00 (free tier) |
| **Total Additional Cost** | **~$0.15/month** |

## Rollback Plan

If something goes wrong:
1. VM still has old SSH access - you can manually fix
2. Secrets stay in Secret Manager (no harm)
3. Remove startup-script metadata to disable auto-run
4. Revert to old workflow in GitHub

No destructive changes, easy to undo.

## Next Steps

1. **Review** the files I created:
   - `MIGRATION_TO_STARTUP_SCRIPT.md` - Detailed setup instructions
   - `scripts/vm-startup.sh` - The startup script
   - `.github/workflows/deploy-sql-startup.yml` - New workflow

2. **Execute** the setup steps in `MIGRATION_TO_STARTUP_SCRIPT.md`

3. **Test** manually first:
   ```bash
   gsutil cp infra/scripts/init-database.sql gs://praxis-sql-bootstrap/
   gcloud compute instances reset sql-linux-vm --zone us-central1-a
   ```

4. **Deploy** via GitHub Actions once manual test works

5. **Celebrate** 🎉 - No more SSH quoting nightmares!

## Questions?

- **Q: What if the startup script fails?**  
  A: VM boots normally, just container doesn't start. Check serial logs. SSH still works for debugging.

- **Q: How do I update the SQL file?**  
  A: Just push to GitHub. Workflow uploads new version to GCS and resets VM.

- **Q: What about downtime?**  
  A: ~30-60 seconds for VM reset. For zero-downtime, we'd need Option B (COS) + instance template.

- **Q: Can I still SSH if needed?**  
  A: Yes! SSH access unchanged. This just means GitHub doesn't need to SSH.
