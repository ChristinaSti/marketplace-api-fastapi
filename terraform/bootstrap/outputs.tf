output "project_id" {
  description = "GCP project ID."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "GCP project number."
  value       = google_project.this.number
}

output "tf_state_bucket" {
  description = "GCS bucket name for Terraform remote state."
  value       = google_storage_bucket.tf_state.name
}

output "cd_service_account_email" {
  description = "Email of the CD service account (for GitHub secrets)."
  value       = google_service_account.cd.email
}

output "wif_provider" {
  description = "Full resource name of the WIF provider (for GitHub secrets: WIF_PROVIDER)."
  value       = google_iam_workload_identity_pool_provider.github.name
}