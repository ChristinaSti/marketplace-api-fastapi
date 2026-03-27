resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
  labels          = var.labels
  # default VPC has overly permissive firewall rules => manage networking yourself!
  auto_create_network = false
  # Two layers of deletion protection: Terraform lifecycle + GCP API
  deletion_policy = "PREVENT"

  lifecycle {
    prevent_destroy = true
  }
}