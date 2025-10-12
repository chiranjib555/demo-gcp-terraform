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
├── main.tf # Core Terraform configuration
├── variables.tf # Input variables (region, project, etc.)
├── outputs.tf # Outputs for resources
├── provider.tf # GCP provider and credentials setup
├── terraform.tfvars # Variable values for demo deployment
└── README.md # Project documentation
