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