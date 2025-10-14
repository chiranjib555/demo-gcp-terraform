# 🤝 Contributing to demo-gcp-terraform

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the repository.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Branch Protection](#branch-protection)
- [Terraform Guidelines](#terraform-guidelines)

## 🌟 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the project
- Show empathy towards other contributors

## 🚀 Getting Started

1. **Fork the repository**
   - Click the "Fork" button in the top-right corner of the repository page

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/demo-gcp-terraform.git
   cd demo-gcp-terraform
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/chiranjib555/demo-gcp-terraform.git
   ```

4. **Install Terraform**
   - Ensure you have Terraform v1.13.3 or compatible version installed
   - Verify installation: `terraform version`

## 💻 Development Workflow

### Creating a Feature Branch

Always create a new branch for your changes:

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create a new feature branch
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - for new features
- `fix/` - for bug fixes
- `docs/` - for documentation updates
- `refactor/` - for code refactoring

### Making Changes

1. **Make your changes**
   - Follow the Terraform best practices (see below)
   - Keep changes focused and atomic

2. **Format your code**
   ```bash
   terraform fmt -recursive
   ```

3. **Validate your changes**
   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

   Commit message guidelines:
   - Use present tense ("Add feature" not "Added feature")
   - Be clear and descriptive
   - Reference issues if applicable (e.g., "Fix #123")

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

## 🔄 Pull Request Process

### Before Submitting a PR

- ✅ Ensure your code follows Terraform best practices
- ✅ Run `terraform fmt` to format your code
- ✅ Run `terraform validate` to check for errors
- ✅ Test your changes with `terraform plan`
- ✅ Update documentation if necessary
- ✅ Ensure your branch is up to date with main

### Submitting a PR

1. **Create a Pull Request**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill in the PR template with:
     - Clear description of changes
     - Related issue numbers
     - Testing performed
     - Screenshots (if applicable)

2. **PR Title Guidelines**
   - Use clear, descriptive titles
   - Examples:
     - "Add support for Cloud Storage bucket creation"
     - "Fix variable naming in provider.tf"
     - "Update README with deployment instructions"

3. **Wait for Review**
   - At least one approval is required before merging
   - Address any feedback or requested changes
   - Keep the conversation constructive and professional

4. **After Approval**
   - Once approved and all checks pass, a maintainer will merge your PR
   - Your feature branch will be deleted after merge

## 🔒 Branch Protection

The `main` branch is protected with the following rules:

- ✅ **Pull requests are required** - No direct commits to main
- ✅ **Approvals required** - At least 1 review approval needed
- ✅ **Status checks must pass** - CI/CD checks must succeed
- ✅ **Branch must be up to date** - Must be synced with main before merge
- ✅ **Conversations must be resolved** - All review comments addressed

For detailed information, see [BRANCH_PROTECTION.md](.github/BRANCH_PROTECTION.md)

## 📦 Terraform Guidelines

### Code Style

- Use consistent naming conventions for resources
- Add meaningful descriptions to variables
- Use modules for reusable components
- Keep configurations DRY (Don't Repeat Yourself)

### File Organization

```
demo-gcp-terraform/
├── main.tf          # Main resource definitions
├── variables.tf     # Input variable declarations
├── outputs.tf       # Output value declarations
├── provider.tf      # Provider configuration
└── terraform.tfvars # Variable values (don't commit sensitive data!)
```

### Variable Naming

- Use lowercase with underscores: `project_id`, `region_name`
- Be descriptive: `gcp_project_id` instead of `pid`
- Add descriptions to all variables

### Security Best Practices

- ❌ Never commit credentials or sensitive data
- ✅ Use variables for all sensitive values
- ✅ Use `.gitignore` to exclude `.tfvars` files with secrets
- ✅ Use GCP service accounts with minimal required permissions
- ✅ Enable and review Terraform state encryption

### Documentation

- Add comments for complex logic
- Update README.md when adding new features
- Document all input variables and outputs
- Include examples of usage

## 🐛 Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Terraform version and environment details

## 🙋 Questions?

If you have questions about contributing:

- Open a GitHub issue with the "question" label
- Review existing issues and pull requests
- Check the documentation in the repository

---

Thank you for contributing to demo-gcp-terraform! 🎉
