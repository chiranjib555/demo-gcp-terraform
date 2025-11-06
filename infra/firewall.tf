# ==============================================================================
# IAP-ONLY ACCESS MODE (Recommended for Production)
# ==============================================================================
# All access goes through Google's Identity-Aware Proxy
# Benefits:
# - Works from ANY IP address (no firewall updates needed!)
# - More secure (Google handles authentication)
# - No exposure to public internet
# ==============================================================================

# SSH (22) via IAP only - public SSH disabled for security
# COMMENTED OUT: Direct SSH access from public IP
# Uncomment below if you need direct SSH access (requires IP maintenance)
# resource "google_compute_firewall" "ssh" {
#   name    = "allow-ssh-admin"
#   network = google_compute_network.vpc.name
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
#   source_ranges = [var.admin_ip_cidr]
# }

# IAP SSH tunnel - for GitHub Actions and admin access from ANY IP
resource "google_compute_firewall" "iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Google's IAP IP range - required for IAP tunneling
  source_ranges = ["35.235.240.0/20"]
}

# SQL Server (1433) via IAP tunnel only - public access disabled
# COMMENTED OUT: Direct SQL access from public IP
# Use sql-tunnel-iap.ps1 to create secure tunnel
# Uncomment below if you need direct SQL access (requires IP maintenance)
# resource "google_compute_firewall" "sql_1433" {
#   name    = "allow-sql-1433-admin"
#   network = google_compute_network.vpc.name
#   allow {
#     protocol = "tcp"
#     ports    = ["1433"]
#   }
#   source_ranges = [var.admin_ip_cidr]
# }
