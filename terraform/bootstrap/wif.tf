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

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    "attribute.event_name"       = "assertion.event_name"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = <<EOT
  assertion.repository == "${var.github_repo}" &&
  assertion.repository_owner == "${local.github_owner}" &&
  assertion.ref == "refs/heads/main" &&
  assertion.event_name == "push"
  EOT
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.cd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
