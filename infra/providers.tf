terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud disabled - using local state for demo environment
  # Uncomment below if you want to use Terraform Cloud:
  # cloud {
  #   organization = "demo-gcp-terraform"
  #   workspaces {
  #     name = "demo-gcp-terraform"
  #   }
  # }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
