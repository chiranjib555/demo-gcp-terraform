# Dedicated service account for the VM runtime
# This SA runs on the VM and has minimal permissions (logging, monitoring)
resource "google_service_account" "vm_runtime" {
  account_id   = "vm-runtime"
  display_name = "VM Runtime SA"
  description  = "Service account for SQL Server VM runtime operations"
}

# Grant logging permissions (so VM can write logs to Cloud Logging)
resource "google_project_iam_member" "vm_runtime_logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_runtime.email}"
}

# Grant monitoring permissions (so VM can write metrics to Cloud Monitoring)
resource "google_project_iam_member" "vm_runtime_monitoring" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_runtime.email}"
}

# Allow GitHub Actions SA to act as the VM runtime SA
# This is needed for gcloud compute ssh to work (impersonation)
resource "google_service_account_iam_member" "github_actions_can_use_vm_sa" {
  service_account_id = google_service_account.vm_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}
