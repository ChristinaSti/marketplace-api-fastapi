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