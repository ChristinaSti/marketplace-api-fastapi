locals {
  github_owner = split("/", var.github_repo)[0]
  github_repo  = split("/", var.github_repo)[1]
}

resource "github_actions_secret" "wif_provider" {
  repository      = local.github_repo
  secret_name     = "WIF_PROVIDER"
  plaintext_value = google_iam_workload_identity_pool_provider.github.name
}

resource "github_actions_secret" "wif_service_account" {
  repository      = local.github_repo
  secret_name     = "WIF_SERVICE_ACCOUNT"
  plaintext_value = google_service_account.cd.email
}
