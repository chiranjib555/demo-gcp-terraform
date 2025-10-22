# SSH (22) locked to your IP; needed for Linux VM access
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-admin"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_ip_cidr]
}

# IAP SSH tunnel for GitHub Actions (no public SSH needed)
# This allows GitHub Actions to SSH via IAP without exposing port 22 publicly
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

# SQL Server (1433) locked to your IP (demo-friendly; prefer IAP in prod)
resource "google_compute_firewall" "sql_1433" {
  name    = "allow-sql-1433-admin"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["1433"]
  }

  source_ranges = [var.admin_ip_cidr]
}
