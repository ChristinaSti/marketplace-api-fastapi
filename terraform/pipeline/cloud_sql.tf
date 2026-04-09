# =============================================================================
# Private, production-grade Cloud SQL PostgreSQL instance.
# TLS-encrypted, IAM-based DB login, no public IP, daily backups with PITR.
#
# Two IAM database users created from service accounts:
# one for migrations (DDL, owns all tables), one for runtime (default DML 
# privileges granted once via an Alembic migration).
# =============================================================================

resource "google_sql_database_instance" "main" {
  name             = "${var.service_name}-db"
  project          = var.project_id
  region           = var.region
  database_version = var.postgres_version

  settings {
    tier                  = var.db_machine_type
    edition               = "ENTERPRISE"
    availability_type     = var.db_availability_type
    disk_size             = var.db_disk_size_gb
    disk_type             = "PD_SSD"
    disk_autoresize       = true
    disk_autoresize_limit = 50 # prevent runaway costs from bugs or attacks

    user_labels = var.labels

    ip_configuration {
      ipv4_enabled       = false # no public access
      private_network    = google_compute_network.main.id
      allocated_ip_range = google_compute_global_address.private_services.name

      server_ca_mode = "GOOGLE_MANAGED_INTERNAL_CA"
      ssl_mode       = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00" # low-traffic window
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_temp_files"
      value = "0"
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  # Protection against accidental deletion on GCP API level and Terraform level
  deletion_protection = true

  lifecycle {
    prevent_destroy = true
  }

  # PSA peering must be established to receive a private IP from the peered range
  depends_on = [
    google_service_networking_connection.private_services,
  ]
}

resource "google_sql_database" "app" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "google_sql_user" "iam_migrate" {
  name     = trimsuffix(google_service_account.migrate.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_sql_user" "iam_runtime" {
  name     = trimsuffix(google_service_account.runtime.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}
