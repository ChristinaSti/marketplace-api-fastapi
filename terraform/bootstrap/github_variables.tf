locals {
  github_owner = split("/", var.github_repo)[0]
  github_repo  = split("/", var.github_repo)[1]
}

resource "github_actions_variable" "wif_provider" {
  repository    = local.github_repo
  variable_name = "WIF_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.github.name
}

resource "github_actions_variable" "wif_service_account" {
  repository    = local.github_repo
  variable_name = "WIF_SERVICE_ACCOUNT"
  value         = google_service_account.cd.email
}

resource "github_actions_variable" "gcp_project_id" {
  repository    = local.github_repo
  variable_name = "GCP_PROJECT_ID"
  value         = google_project.this.project_id
}

resource "github_actions_variable" "gcp_region" {
  repository    = local.github_repo
  variable_name = "GCP_REGION"
  value         = var.region
}

resource "github_actions_variable" "tf_state_bucket" {
  repository    = local.github_repo
  variable_name = "TF_STATE_BUCKET"
  value         = google_storage_bucket.tf_state.name
}
