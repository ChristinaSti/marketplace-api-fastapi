terraform {
  required_version = "~> 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.18.0"
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