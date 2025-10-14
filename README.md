# 🌍 demo-gcp-terraform

**A demo repository for provisioning and managing Google Cloud Platform (GCP) resources using Terraform v1.13.3.**  
This project showcases how to build, plan, and apply Infrastructure as Code (IaC) using Terraform — integrated with VS Code, GitHub, and Semaphore UI.

---

## 🚀 Project Overview

This repository demonstrates:
- Terraform-based automation for GCP resource provisioning.
- Modular and reusable Terraform structure.
- Integration with Semaphore UI for visual Terraform runs.
- GitHub as version control for IaC projects.
- Support for Terraform v1.13.3 (tested locally and via Docker).

---

## 📁 Repository Structure

demo-gcp-terraform/
│
├── .github/ # GitHub-specific configurations
│   ├── BRANCH_PROTECTION.md # Branch protection setup guide
│   ├── CONTRIBUTING.md # Contribution guidelines
│   └── CODEOWNERS # Code owners for PR reviews
├── main.tf # Core Terraform configuration
├── variables.tf # Input variables (region, project, etc.)
├── outputs.tf # Outputs for resources
├── provider.tf # GCP provider and credentials setup
├── terraform.tfvars # Variable values for demo deployment
└── README.md # Project documentation

---

## 🔒 Branch Protection

This repository has branch protection enabled for the `main` branch to ensure code quality and prevent accidental changes.

### Key Protection Rules:
- ✅ Pull requests are required before merging
- ✅ At least 1 approval required from code owners
- ✅ All conversations must be resolved
- ✅ Branch must be up to date before merging

**For administrators**: To configure branch protection settings, please refer to [`.github/BRANCH_PROTECTION.md`](.github/BRANCH_PROTECTION.md) for detailed setup instructions.

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](.github/CONTRIBUTING.md) before submitting a pull request.

### Quick Start for Contributors:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes and commit: `git commit -m "Add feature"`
4. Push to your fork: `git push origin feature/your-feature`
5. Open a Pull Request

All pull requests require at least one approval before merging.
