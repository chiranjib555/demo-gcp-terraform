terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud enabled - remote state management
  cloud {
    organization = "demo-gcp-terraform"
    workspaces {
      name = "demo-gcp-terraform"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
