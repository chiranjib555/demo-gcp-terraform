# GitHub Secrets Setup Guide

## Required Secrets

You need to add 4 secrets to your GitHub repository. Here's what you need:

### 1. GCP_PROJECT_ID
**Value:**
```
praxis-gantry-475007-k0
```

### 2. GCP_SA_KEY
**Value:** Copy the entire contents of `sa-key.json` file (created in infra directory)

The file contains:
```json
{
  "type": "service_account",
  "project_id": "praxis-gantry-475007-k0",
  ...
}
```

**Important:** Copy the ENTIRE JSON content from the file.

### 3. SQL_SA_PASSWORD
**Value:** Your SQL Server SA password from `terraform.tfvars`

Default from your config:
```
ChangeMe_Strong#SA_2025!
```

### 4. SQL_CI_PASSWORD
**Value:** Your SQL CI user password from `terraform.tfvars`

Default from your config:
```
ChangeMe_UseStrongPwd#2025!
```

---

## How to Add Secrets to GitHub

### Step 1: Go to Your Repository Settings
1. Open your GitHub repository: `https://github.com/YOUR_USERNAME/YOUR_REPO`
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add Each Secret
For each secret above:

1. Click **New repository secret**
2. Enter the **Name** (e.g., `GCP_PROJECT_ID`)
3. Enter the **Value** (copy from above)
4. Click **Add secret**

Repeat for all 4 secrets.

---

## Quick Copy-Paste Values

### GCP_PROJECT_ID
```
praxis-gantry-475007-k0
```

### GCP_SA_KEY
**Location:** `C:\Users\PC\demo-gcp-terraform\infra\sa-key.json`

**To copy:**
```powershell
Get-Content C:\Users\PC\demo-gcp-terraform\infra\sa-key.json | Set-Clipboard
# Now paste in GitHub (Ctrl+V)
```

### SQL_SA_PASSWORD
```
ChangeMe_Strong#SA_2025!
```

### SQL_CI_PASSWORD
```
ChangeMe_UseStrongPwd#2025!
```

---

## Verification Checklist

After adding secrets, verify:
- [ ] 4 secrets are listed in Settings → Secrets and variables → Actions
- [ ] Secret names match exactly (case-sensitive):
  - `GCP_PROJECT_ID`
  - `GCP_SA_KEY`
  - `SQL_SA_PASSWORD`
  - `SQL_CI_PASSWORD`
- [ ] No typos in values
- [ ] GCP_SA_KEY is valid JSON (starts with `{` and ends with `}`)

---

## Next Steps

Once secrets are configured:

1. Go to **Actions** tab in your GitHub repository
2. Select **Deploy SQL Server to GCP** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Select action: `deploy`
6. Click **Run workflow** button

The workflow will:
- Connect to your VM via IAP tunnel
- Deploy SQL Server 2022 container
- Run database initialization
- Create `DemoDB` database and `ci_user`

---

## Troubleshooting

### "Secret not found" error
- Check secret names are exactly as specified (case-sensitive)
- Make sure you're adding them as **repository secrets**, not environment secrets

### "Invalid credentials" error
- Verify GCP_SA_KEY is complete JSON (check for truncation)
- Ensure no extra spaces or characters

### "Permission denied" error
- Verify the service account has the correct IAM roles (already done via gcloud)

---

**Ready?** Add the secrets and then run the workflow!
