resource "google_service_account" "cd" {
  project      = google_project.this.project_id
  account_id   = "github-actions-cd"
  display_name = "GitHub Actions CD"
  description  = "Service account used by the CD pipeline (GitHub Actions via WIF)."

  depends_on = [google_project_service.apis]
}

# Least-privilege IAM roles for the CD service account
locals {
  cd_roles = [
    "roles/run.admin",                   # deploy Cloud Run services & jobs
    "roles/iam.serviceAccountUser",      # act as the Cloud Run runtime SA
    "roles/artifactregistry.writer",     # push Docker images
    "roles/secretmanager.secretAccessor", # read database secrets
    "roles/cloudsql.client",             # connect to Cloud SQL
    "roles/storage.objectAdmin",         # read/write Terraform state
  ]
}

resource "google_project_iam_member" "cd" {
  for_each = toset(local.cd_roles)

  project = google_project.this.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cd.email}"
}