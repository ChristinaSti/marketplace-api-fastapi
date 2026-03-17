variable "project_id" {
  description = "Globally unique GCP project ID."
  type        = string
}

variable "project_name" {
  description = "Human-readable project display name."
  type        = string
  default     = "Marketplace API"
}

variable "org_id" {
  description = "GCP Organization ID the project belongs to."
  type        = string
}

variable "billing_account" {
  description = "Billing Account ID to attach to the project."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Default GCP region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to the project for cost tracking and organization."
  type        = map(string)
  default = {
    managed_by  = "terraform"
    environment = "production"
    team        = "backend"
  }
}

variable "github_repo" {
  description = "GitHub repository (owner/repo) allowed to authenticate via WIF."
  type        = string
}

variable "github_token" {
  description = "GitHub token for setting GitHub secrets."
  type        = string
  sensitive   = true
}