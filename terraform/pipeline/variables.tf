variable "project_id" {
  description = "GCP project ID where all resources will be provisioned."
  type        = string
}

variable "region" {
  description = "Default GCP region for all regional resources."
  type        = string
}

variable "service_name" {
  description = "Base name used for Cloud Run service, Artifact Registry repo, etc."
  type        = string
}

variable "labels" {
  description = "Labels applied to all resources for cost tracking and organization."
  type        = map(string)
  default = {
    managed_by  = "terraform"
    environment = "production"
    team        = "backend"
  }
}
