terraform {
  required_version = "~> 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.18.0"
    }
  }
  # no backend block configuration - bootstrap state is intentionally local 
  # to be run ONCE by a human with org-admin permissions
}

provider "google" {
  # No default project - it is created
}

locals {
  apis = [
    "cloudresourcemanager.googleapis.com", # project metadata an resources
    "iam.googleapis.com",                  # IAM policies and service accounts
    "iamcredentials.googleapis.com",       # Workload Identity Federation
    "sts.googleapis.com",                  # Security Token Service (WIF)
    "storage.googleapis.com",              # GCS (Terraform state bucket)
    "artifactregistry.googleapis.com",     # Docker image registry
    "run.googleapis.com",                  # Cloud Run
    "compute.googleapis.com",              # networking (Cloud Run dependency)
    "secretmanager.googleapis.com",        # Secret Manager
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}