resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.this.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.this.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  # Map GitHub's OIDC token claims
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Only allow tokens from GitHub's OIDC issuer
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Restrict to this specific repository
  attribute_condition = "assertion.repository == \"${var.github_repo}\""
}

# Allow the GitHub WIF provider to impersonate the CD service account
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.cd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
