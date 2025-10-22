# 🔒 Branch Protection Setup Guide

This guide explains how to configure branch protection rules for the `main` branch to ensure code quality and prevent accidental changes.

## 📋 Branch Protection Rules

### Setting Up Branch Protection for Main Branch

Follow these steps to protect the `main` branch:

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click on **Settings** tab
   - Select **Branches** from the left sidebar

2. **Add Branch Protection Rule**
   - Click **Add rule** or **Add branch protection rule**
   - In the "Branch name pattern" field, enter: `main`

3. **Configure Protection Settings**

   #### Recommended Settings:

   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: Set to at least `1` reviewer
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from Code Owners (if CODEOWNERS file exists)

   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Add any CI/CD checks that should pass (e.g., tests, linting)

   - ✅ **Require conversation resolution before merging**
     - Ensures all review comments are addressed

   - ✅ **Require signed commits** (optional but recommended)
     - Adds an extra layer of security

   - ✅ **Include administrators**
     - Applies these rules to repository administrators as well

   - ✅ **Restrict who can push to matching branches** (optional)
     - Limit direct pushes to specific users or teams

   - ✅ **Allow force pushes**: Disabled
   - ✅ **Allow deletions**: Disabled

4. **Save Changes**
   - Scroll down and click **Create** or **Save changes**

## 🎯 Benefits of Branch Protection

- **Prevents direct commits to main**: All changes must go through pull requests
- **Enforces code review**: Requires at least one approval before merging
- **Maintains code quality**: Ensures CI/CD checks pass before merging
- **Reduces errors**: Prevents accidental force pushes or branch deletions
- **Improves collaboration**: Encourages team review and discussion

## 🔄 Workflow After Protection

Once branch protection is enabled:

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes and commit**
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin feature/your-feature-name
   ```

3. **Open a Pull Request**
   - Go to GitHub and create a PR from your feature branch to `main`
   - Request reviews from team members
   - Address any feedback

4. **Merge after approval**
   - Once approved and checks pass, merge the PR
   - The feature branch can then be deleted

## 📚 Additional Resources

- [GitHub Branch Protection Rules Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Pull Request Documentation](https://docs.github.com/en/pull-requests)
- [Code Review Best Practices](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)

## 🚨 Important Notes

- These settings can only be configured by repository administrators
- Existing branches and commits are not affected by new protection rules
- You can always modify or remove protection rules if needed
- Consider setting up CODEOWNERS file for automatic reviewer assignment
