# =============================================================================
# Application-layer infrastructure managed by the GitHub Actions CD pipeline.
#
# Provisions networking, Artifact Registry, Cloud SQL, and service accounts.
# All database auth is passwordless (IAM database authentication).
#
# Prerequisites (created once by terraform/bootstrap/):
#   GCP project, state bucket, WIF GCP authentication, CD service account, APIs.
#
# Terraform manages only slow-changing infrastructure while the fast-changing 
# Cloud Run service deployment is handled by the CD pipeline directly.
# =============================================================================

terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.18"
    }
  }

  backend "gcs" {
    prefix = "pipeline"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}