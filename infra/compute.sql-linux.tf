# Static IP (reuse name you already created, or keep as is)
resource "google_compute_address" "sqlvm_ip" {
  name   = "sqlvm-ip"
  region = var.region

  # Prevent accidental deletion during tear down/spin up cycles
  lifecycle {
    prevent_destroy = true
  }
}

# Persistent disk for SQL Server data (survives VM destroy/recreate)
resource "google_compute_disk" "sql_data" {
  name = "sql-data-disk"
  type = "pd-ssd" # Better performance for databases
  zone = var.zone
  size = var.disk_size_gb

  # Prevent accidental deletion - your data stays safe
  lifecycle {
    prevent_destroy = true
  }
}

# Debian 11 image (stable and free trial compatible)
data "google_compute_image" "ubuntu" {
  family  = "debian-11"
  project = "debian-cloud"
}

# ==============================================================================
# VM RESOURCE COMMENTED OUT - VM will be destroyed
# To recreate the VM, uncomment the resource below
# ==============================================================================
# resource "google_compute_instance" "sqlvm" {
#   name         = "sql-linux-vm"
#   machine_type = "e2-standard-2" # adjust if needed
#   zone         = var.zone
#   tags         = ["sql", "ssh"] # match firewall tags if you use them
#
#   boot_disk {
#     initialize_params {
#       image = data.google_compute_image.ubuntu.self_link
#       size  = 50
#       type  = "pd-balanced"
#     }
#   }
#
#   # Attach persistent disk for SQL Server data
#   attached_disk {
#     source      = google_compute_disk.sql_data.id
#     device_name = "sql-data"
#     mode        = "READ_WRITE"
#   }
#
#   network_interface {
#     subnetwork = google_compute_subnetwork.subnet.id
#     access_config {
#       nat_ip = google_compute_address.sqlvm_ip.address
#     }
#   }
#
#   # Minimal startup script: only prep VM, mount disk, install Docker
#   # SQL Server deployment handled by "Deploy SQL Server" workflow
#   metadata = {
#     startup-script = templatefile("${path.module}/scripts/vm-prep.sh.tftpl", {
#       device_name = "sql-data"
#     })
#     enable-oslogin = "FALSE" # DISABLED - Use metadata-based SSH keys for simpler IAP access
#   }
#
#   # Allow stopping for updates (needed for disk attachment and metadata changes)
#   allow_stopping_for_update = true
#
#   # Optional scheduling
#   scheduling {
#     automatic_restart   = true
#     on_host_maintenance = "MIGRATE"
#   }
#
#   # Dedicated VM runtime service account with minimal permissions
#   service_account {
#     email = google_service_account.vm_runtime.email
#     scopes = [
#       "https://www.googleapis.com/auth/cloud-platform",  # Needed for Secret Manager access
#     ]
#   }
# }
