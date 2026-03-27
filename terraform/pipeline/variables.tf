# =============================================================================
# Customizable variables. 
# Adjust values in pipeline.tfvars and common.tfvars.
# =============================================================================
# ── Project ──────────────────────────────────────────────────────────

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

# ── Cloud SQL ────────────────────────────────────────────────────────

variable "postgres_version" {
  description = "PostgreSQL major version for Cloud SQL."
  type        = string
  default     = "POSTGRES_18"
}

variable "db_machine_type" {
  description = <<-EOT
    Cloud SQL machine type.

    Dev: db-f1-micro - shared vCPU can cause latency spikes, small memory, low cost
    Production recommendation: chose machine type with dedicated vCPU(s). Monitor 
    CPU and memory usage and Disk I/O to determine the required resources, which
    depends on complexity and number of simultaneous queries and dataset size.
  EOT
  type        = string
  default     = "db-f1-micro"
}

variable "db_availability_type" {
  description = <<-EOT
    Cloud SQL availability type.

    Dev:  ZONAL - single zone, no automatic failover, low cost
    Production recommendation: REGIONAL - high availability with automatic 
    failover to standby in different zone within the selected region, 
    cost ~ 2x ZONAL
  EOT
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.db_availability_type)
    error_message = "Must be ZONAL or REGIONAL."
  }
}

variable "db_disk_size_gb" {
  description = "Initial disk size in GB. Cloud SQL auto-grows."
  type        = number
  default     = 10
}

variable "db_name" {
  description = "Name of the application database."
  type        = string
  default     = "marketplace"
}

# ── Cloud Run ────────────────────────────────────────────────────────

variable "cloud_run_min_instances" {
  description = <<-EOT
    Minimum number of Cloud Run instances.
    To avoid cold-start latency, i.e. in production, keep at least one instance warm.
  EOT
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = <<-EOT
    Maximum number of Cloud Run instances.
    Estimate for production: 
    (peak_requests_per_second × avg_latency_sec) / concurrency_per_instance.
  EOT
  type        = number
  default     = 3
}

variable "cloud_run_cpu" {
  description = "CPU allocation per Cloud Run instance."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation per Cloud Run instance."
  type        = string
  default     = "512Mi"
}

variable "cloud_run_concurrency" {
  description = "Maximum concurrent requests per Cloud Run instance."
  type        = number
  default     = 80
}

variable "cloud_run_timeout" {
  description = <<-EOT
  Maximum request duration before Cloud Run terminates it by closing the 
  network connection to the service and returning a 504 error.
  60 s is enough for most API calls but may need adjustment for heavy processing requests.
  EOT
  type        = string
  default     = "60s"
}

variable "cloud_run_ingress" {
  description = <<-EOT
    Cloud Run ingress setting.
    Setting to "all" allows user to reach the service from the public internet which is 
    suitable for many APIs.
  EOT
  type        = string
  default     = "all"

  validation {
    condition     = contains(["all", "internal", "internal-and-cloud-load-balancing"], var.cloud_run_ingress)
    error_message = "Must be all, internal, or internal-and-cloud-load-balancing."
  }
}
