# ✅ Branch Protection Setup Checklist

This checklist helps repository administrators quickly set up branch protection for the `main` branch.

## 🎯 Quick Setup Steps

### 1️⃣ Access Repository Settings
- [ ] Go to https://github.com/chiranjib555/demo-gcp-terraform
- [ ] Click **Settings** tab (requires admin access)
- [ ] Select **Branches** from the left sidebar

### 2️⃣ Create Branch Protection Rule
- [ ] Click **Add rule** or **Add branch protection rule**
- [ ] Enter `main` in the "Branch name pattern" field

### 3️⃣ Enable Core Protection Settings

#### Required Settings (Recommended):
- [ ] ✅ **Require a pull request before merging**
  - [ ] Require approvals: `1` (minimum)
  - [ ] Dismiss stale pull request approvals when new commits are pushed
  - [ ] Require review from Code Owners

- [ ] ✅ **Require status checks to pass before merging**
  - [ ] Require branches to be up to date before merging

- [ ] ✅ **Require conversation resolution before merging**

#### Additional Security Settings (Recommended):
- [ ] ✅ **Include administrators** (applies rules to admins too)
- [ ] ✅ **Restrict who can push to matching branches** (optional)
- [ ] ❌ **Allow force pushes** (should be DISABLED)
- [ ] ❌ **Allow deletions** (should be DISABLED)

### 4️⃣ Save Configuration
- [ ] Scroll down and click **Create** button
- [ ] Verify the rule appears in the branch protection rules list

## 🧪 Testing Branch Protection

After setup, verify the protection is working:

1. **Test Direct Push (Should Fail)**
   ```bash
   # Try to push directly to main (should be blocked)
   git checkout main
   git push origin main
   # Expected: Error message about branch protection
   ```

2. **Test PR Workflow (Should Work)**
   ```bash
   # Create feature branch
   git checkout -b test/branch-protection
   echo "test" > test.txt
   git add test.txt
   git commit -m "Test branch protection"
   git push origin test/branch-protection
   # Then create PR on GitHub - should work normally
   ```

3. **Test PR Merge Without Approval (Should Fail)**
   - Create a PR
   - Try to merge without approval
   - Expected: Merge button disabled or warning shown

4. **Test PR Merge With Approval (Should Work)**
   - Create a PR
   - Get approval from code owner
   - Merge should now be enabled

## 📋 Verification Checklist

Confirm these behaviors after setup:

- [ ] Cannot push directly to `main` branch
- [ ] Cannot merge PR without at least 1 approval
- [ ] Cannot merge PR with unresolved conversations
- [ ] Cannot merge PR if branch is out of date
- [ ] Cannot force push to `main`
- [ ] Cannot delete `main` branch
- [ ] Code owners are automatically requested as reviewers (when CODEOWNERS file is used)

## 🎉 Post-Setup

Once branch protection is enabled:

1. **Inform Team Members**
   - [ ] Notify team about new branch protection rules
   - [ ] Share [CONTRIBUTING.md](.github/CONTRIBUTING.md) guidelines
   - [ ] Explain the PR workflow

2. **Update Documentation**
   - [x] README.md updated with branch protection info
   - [x] Contributing guidelines created
   - [x] Branch protection guide available

3. **Monitor and Adjust**
   - [ ] Monitor if rules are too strict/lenient
   - [ ] Adjust number of required approvals as needed
   - [ ] Add status checks as CI/CD is implemented

## 🔗 Additional Resources

- [Detailed Branch Protection Guide](BRANCH_PROTECTION.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

## ⚠️ Important Notes

- Branch protection settings can only be modified by repository administrators
- These rules do not affect existing commits or branches
- Rules can be temporarily disabled if needed (not recommended)
- Consider enabling signed commits for additional security
- Regular audits of protection rules are recommended

---

**Status**: Ready for implementation  
**Last Updated**: 2025-10-14  
**Maintainer**: @chiranjib555
