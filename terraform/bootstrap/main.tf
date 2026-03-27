# =============================================================================
# Bootstrap — run ONCE by a human with org-admin permissions.
#
# Creates everything the CD pipeline needs before it can run (solves the chicken-
# and-egg problem): GCP project, APIs, state bucket, Workload Identity
# Federation, CD service account, and GitHub Actions variables.
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply -var-file=../common.tfvars -var-file=bootstrap.tfvars
#
# Prerequisites on YOUR machine:
#   - roles/resourcemanager.projectCreator  (on the org)
#   - roles/billing.user                    (on the billing account)
# =============================================================================

terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.18"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  
  # The backend code was added after the state was created in a first bootstrap terraform run
  # in order to centrally save the bootstrap state.
  # Since this block is executed during terraform init, it cannot access 
  # google_project.tf_state.name => bucket must be hardcoded
  # For first-time run add the flag: terraform init -migrate-state
  backend "gcs" {
    bucket = "marketplace-api-prod-tf-state"
    prefix = "bootstrap"
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
    "vpcaccess.googleapis.com",
    "containerscanning.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}