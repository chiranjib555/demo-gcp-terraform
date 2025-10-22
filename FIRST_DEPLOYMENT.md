# 🚀 First SQL Server Deployment - Step by Step

## ✅ Pre-Deployment Checklist

### Infrastructure Status
- [x] ✅ VM is running (sql-linux-vm)
- [x] ✅ Docker installed (version 28.5.1)
- [x] ✅ Persistent disk mounted (/mnt/sqldata)
- [x] ✅ IAP SSH working
- [x] ✅ Service account created with IAM roles
- [x] ✅ GitHub Actions workflow file exists

**Status:** Infrastructure is READY! 🎉

---

## 📋 Step 1: Add GitHub Secrets (Required)

### Navigate to GitHub Secrets
1. Go to your GitHub repository
2. Click **Settings** tab (top right)
3. In left sidebar: **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Add These 4 Secrets:

#### Secret 1: GCP_PROJECT_ID
- Name: `GCP_PROJECT_ID`
- Value: `praxis-gantry-475007-k0`
- Click **Add secret**

#### Secret 2: GCP_SA_KEY
- Name: `GCP_SA_KEY`
- Value: **Press Ctrl+V** (it's already in your clipboard!)
  - Should start with `{` and end with `}`
  - Should contain `"type": "service_account"`
- Click **Add secret**

#### Secret 3: SQL_SA_PASSWORD
- Name: `SQL_SA_PASSWORD`
- Value: `ChangeMe_Strong#SA_2025!`
- Click **Add secret**

#### Secret 4: SQL_CI_PASSWORD
- Name: `SQL_CI_PASSWORD`
- Value: `ChangeMe_UseStrongPwd#2025!`
- Click **Add secret**

### Verify Secrets
You should now see 4 secrets listed:
```
✓ GCP_PROJECT_ID
✓ GCP_SA_KEY
✓ SQL_SA_PASSWORD
✓ SQL_CI_PASSWORD
```

---

## 🎯 Step 2: Commit and Push Workflow (If Not Already)

Check if you need to push the workflow file:

```powershell
cd C:\Users\PC\demo-gcp-terraform
git status
```

If you see uncommitted files, commit them:

```powershell
git add .github/workflows/deploy-sql.yml
git add infra/
git add *.md
git commit -m "Add tear down/spin up infrastructure with GitHub Actions deployment"
git push origin main
```

---

## 🚀 Step 3: Run the Workflow

### Option A: Via GitHub UI (Recommended for First Run)

1. Go to your GitHub repository
2. Click **Actions** tab (top)
3. In the left sidebar, click **Deploy SQL Server to GCP**
4. Click **Run workflow** button (right side)
5. Select:
   - Branch: `main`
   - Action: `deploy`
6. Click the green **Run workflow** button
7. Wait ~2 minutes for deployment

### Option B: Trigger via Git Push

The workflow also runs automatically when you push changes to:
- `infra/scripts/init-database.sql`
- `.github/workflows/deploy-sql.yml`

---

## 👀 Step 4: Monitor the Deployment

### Watch the Workflow Run
1. In the **Actions** tab, you'll see a new workflow run appear
2. Click on it to see real-time logs
3. Watch each step complete:
   - ✅ Checkout code
   - ✅ Authenticate to Google Cloud
   - ✅ Set up Cloud SDK
   - ✅ Deploy SQL Server Container
   - ✅ Clean up

### Expected Timeline
- **Total time:** ~2-3 minutes
- Authentication: 10 seconds
- SSH via IAP: 10 seconds
- Container deployment: 60 seconds
- SQL Server startup: 30 seconds
- Database initialization: 20 seconds

---

## ✅ Step 5: Verify Deployment

### Check from Workflow Logs
The workflow will show:
```
✅ SQL Server 2022 is running
✅ Container: mssql
✅ Database: DemoDB
✅ User: ci_user with db_owner role
```

### Test from Your Local Machine

```powershell
# Test SQL Server connection
$connectionString = "Server=34.57.37.222,1433;Database=DemoDB;User Id=ci_user;Password=ChangeMe_UseStrongPwd#2025!;TrustServerCertificate=True;"

# If you have SqlServer module:
Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT @@VERSION; SELECT name FROM sys.databases;"
```

### Test via SSH
```bash
echo y | gcloud compute ssh sql-linux-vm --project=praxis-gantry-475007-k0 --zone=us-central1-a --tunnel-through-iap --command="sudo docker ps"
```

Expected output:
```
CONTAINER ID   IMAGE                                        STATUS
abc123def456   mcr.microsoft.com/mssql/server:2022-latest   Up 2 minutes
```

---

## 🎉 Success Indicators

You'll know it worked when you see:

1. ✅ Workflow shows green checkmark
2. ✅ "Deployment complete!" message in logs
3. ✅ Can query SQL Server from local machine
4. ✅ Database "DemoDB" exists
5. ✅ User "ci_user" has db_owner role

---

## 🔧 If Something Goes Wrong

### Common Issues & Solutions

#### Issue: "Secret GCP_SA_KEY not found"
**Solution:** Check secret name is exactly `GCP_SA_KEY` (case-sensitive)

#### Issue: "Invalid credentials"
**Solution:** 
1. Re-copy the service account key: `Get-Content C:\Users\PC\demo-gcp-terraform\infra\sa-key.json | Set-Clipboard`
2. Update the GCP_SA_KEY secret in GitHub
3. Re-run the workflow

#### Issue: "Permission denied (publickey)"
**Solution:** IAM roles are correct (we just verified this), wait 1 minute and retry

#### Issue: "Could not SSH into the instance"
**Solution:**
1. Check VM is running: `.\check-status.ps1`
2. If stopped, spin up: `.\spinup.ps1`
3. Wait 2 minutes for startup script
4. Re-run workflow

#### Issue: "Container failed to start"
**Solution:** Check password complexity:
- Must have uppercase, lowercase, digit, special char
- Minimum 8 characters
- Current passwords meet requirements ✅

---

## 📊 What Happens During Deployment

```
1. GitHub Actions starts
   ↓
2. Authenticates with GCP_SA_KEY
   ↓
3. SSH to VM via IAP tunnel (secure!)
   ↓
4. Checks for existing container
   ↓
5. Stops old container (if exists)
   ↓
6. Pulls SQL Server 2022 image
   ↓
7. Starts new container with:
   - Persistent disk volumes mounted
   - Port 1433 exposed
   - SA password configured
   ↓
8. Waits for SQL Server to be ready
   ↓
9. Copies init-database.sql to VM
   ↓
10. Runs initialization:
    - Creates database "DemoDB"
    - Creates login "ci_user"
    - Grants db_owner role
    - Creates DeploymentLog table
    ↓
11. Verifies deployment
    ↓
12. ✅ SUCCESS!
```

---

## 🎯 Next Steps After First Deployment

Once deployment succeeds:

1. **Test the tear down / spin up cycle:**
   ```powershell
   .\teardown.ps1  # Destroy VM
   .\spinup.ps1    # Recreate VM
   # Run GitHub Actions workflow again
   # Verify data persists
   ```

2. **Create test data:**
   ```sql
   USE DemoDB;
   CREATE TABLE TestTable (Id INT, Name NVARCHAR(100));
   INSERT INTO TestTable VALUES (1, 'First deployment!');
   ```

3. **Set up automated tear down/spin up:**
   - Use Windows Task Scheduler
   - Schedule teardown at 6 PM
   - Schedule spinup + deployment at 8 AM

4. **Monitor costs:**
   - Go to GCP Console → Billing
   - Set up budget alerts
   - Track daily costs

---

## 📚 Reference Links

- **Workflow Logs:** GitHub → Actions → Latest run
- **VM Serial Console:** `gcloud compute instances get-serial-port-output sql-linux-vm --zone=us-central1-a`
- **Docker Logs:** `echo y | gcloud compute ssh sql-linux-vm --zone=us-central1-a --tunnel-through-iap --command="sudo docker logs mssql"`
- **Status Check:** `.\check-status.ps1`

---

## ✅ Ready to Deploy?

**Checklist before you click "Run workflow":**
- [ ] All 4 GitHub Secrets added
- [ ] Workflow file is in repository
- [ ] VM is running (check with `.\check-status.ps1`)
- [ ] IAP SSH tested and working ✅

**Everything is ready! Go ahead and run the workflow!** 🚀

---

**Expected result:** In ~2 minutes, you'll have SQL Server 2022 running with your database ready to use!
