resource "google_service_account" "cd" {
  project      = google_project.this.project_id
  account_id   = "github-actions-cd"
  display_name = "GitHub Actions CD"
  description  = "Service account used by the CD pipeline (GitHub Actions via WIF)."

  depends_on = [google_project_service.apis]
}

locals {
  cd_roles = [
    "roles/run.admin",
    "roles/iam.serviceAccountUser", 
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/storage.objectAdmin",
  ]
}

resource "google_project_iam_member" "cd" {
  for_each = toset(local.cd_roles)

  project = google_project.this.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cd.email}"
}