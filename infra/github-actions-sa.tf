# Service account for GitHub Actions to manage VM and deploy SQL Server
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-deployer"
  display_name = "GitHub Actions Deployer"
  description  = "Service account for GitHub Actions to deploy SQL Server via IAP"
}

# Grant necessary roles for IAP SSH and VM management
# NOTE: OS Login is DISABLED on VM - using metadata-based SSH keys instead
resource "google_project_iam_member" "github_actions_instance_admin" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_iap_tunnel" {
  project = var.project
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_compute_viewer" {
  project = var.project
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Service account key creation commented out - key already exists and is stored in GitHub Secrets
# If you need to recreate the key, uncomment this and run terraform apply
# resource "google_service_account_key" "github_actions_key" {
#   service_account_id = google_service_account.github_actions.name
# }

# Output the private key (warning: sensitive!)
# output "github_actions_sa_key" {
#   value       = google_service_account_key.github_actions_key.private_key
#   sensitive   = true
#   description = "Private key for GitHub Actions service account (base64 encoded JSON)"
# }
