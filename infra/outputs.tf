output "network_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "sqlvm_external_ip" {
  value       = google_compute_address.sqlvm_ip.address
  description = "Public IP of the SQL VM (remains stable across rebuilds)"
}

output "persistent_disk_name" {
  value       = google_compute_disk.sql_data.name
  description = "Name of the persistent disk for SQL Server data"
}

output "github_actions_sa_email" {
  value       = google_service_account.github_actions.email
  description = "Service account email for GitHub Actions"
}

output "connection_string_template" {
  value       = "Server=${google_compute_address.sqlvm_ip.address},1433;Database=DemoDB;User Id=ci_user;Password=<SQL_CI_PASSWORD>;TrustServerCertificate=True;"
  description = "SQL Server connection string template"
}
