# =============================================================================
# Two service accounts with least-privilege GCP roles:
# - runtime: DML-only database access, Cloud Trace and log writing
# - migrate: DDL + GRANT database access, log writing
# =============================================================================

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "db-run"
  display_name = "${var.service_name} Cloud Run Runtime"
  description  = "Runtime identity for the ${var.service_name} Cloud Run service. DML-only database access."
}

locals {
  runtime_roles = [
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
  ]
}

resource "google_project_iam_member" "runtime" {
  for_each = toset(local.runtime_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_service_account" "migrate" {
  project      = var.project_id
  account_id   = "db-migrate"
  display_name = "${var.service_name} Cloud Run Migration"
  description  = "Migration identity for the ${var.service_name} Alembic job. DDL + GRANT access."
}

locals {
  migrate_roles = [
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles/logging.logWriter",
  ]
}

resource "google_project_iam_member" "migrate" {
  for_each = toset(local.migrate_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.migrate.email}"
}
