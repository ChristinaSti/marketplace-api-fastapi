resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
  labels          = var.labels
  # default VPC has overly permissive firewall rules => manage networking yourself!
  auto_create_network = false
  # prevent_destroy in lifecycle is the terraform-side guard, deletion_policy adds a 
  # complementary GCP API-side guard
  deletion_policy = "PREVENT"

  lifecycle {
    prevent_destroy = true
  }
}