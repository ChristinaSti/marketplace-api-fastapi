# =============================================================================
# Bootstrap — run ONCE by a human with org-admin permissions
#
# This config creates everything the CD pipeline needs to exist before it can
# run, solving the chicken-and-egg problem:
#   - GCP project (with billing)
#   - Essential APIs
#   - Terraform remote-state bucket
#   - Workload Identity Federation (keyless GitHub Actions → GCP auth)
#   - CD service account with least-privilege IAM roles
#   - GitHub Actions secrets (WIF_PROVIDER, WIF_SERVICE_ACCOUNT)
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# State is kept LOCAL on purpose — this config is run once and rarely touched.
# If you need to re-run it (e.g. to add an API), just re-apply from your
# machine. The local state file (terraform.tfstate) should NOT be committed —
# it is already in .gitignore.
#
# Prerequisites on YOUR machine:
#   - Google account with:
#     - roles/resourcemanager.projectCreator  (on the org)
#     - roles/billing.user                    (on the billing account)
# =============================================================================

terraform {
  required_version = "~> 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.18.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "google" {}

provider "github" {
  owner = local.github_owner
  token = var.github_token
}

locals {
  apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}