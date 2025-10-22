variable "project" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP zone"
}

variable "admin_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR, e.g., 203.0.113.10/32"
}

variable "sql_admin_login" {
  type        = string
  description = "SQL login for CI/CD access (non-SA)"
  default     = "ci_user"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL password for CI/CD access"
  sensitive   = true
}

variable "sql_sa_password" {
  type        = string
  sensitive   = true
  description = "SA password for SQL Server container"
}

variable "db_name" {
  type        = string
  default     = "DemoDB"
  description = "Database to create at bootstrap"
}

variable "disk_size_gb" {
  type        = number
  default     = 100
  description = "Size of persistent disk for SQL Server data (GB)"
}
