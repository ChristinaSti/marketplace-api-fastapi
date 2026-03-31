# =============================================================================
# Outputs consumed by the CD pipeline.
# =============================================================================

output "vpc_connector_name" {
  description = "Fully-qualified name of the Serverless VPC Access connector."
  value       = google_vpc_access_connector.main.id
}

output "db_iam_migrate_user" {
  description = "PostgreSQL IAM username for the migrate SA (SA email minus .gserviceaccount.com)."
  value       = trimsuffix(google_service_account.migrate.email, ".gserviceaccount.com")
}

output "db_iam_runtime_user" {
  description = "PostgreSQL IAM username for the runtime SA (SA email minus .gserviceaccount.com)."
  value       = trimsuffix(google_service_account.runtime.email, ".gserviceaccount.com")
}

output "migrate_service_account" {
  description = "Email of the Cloud Run migration service account."
  value       = google_service_account.migrate.email
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name (PROJECT:REGION:INSTANCE)."
  value       = google_sql_database_instance.main.connection_name
}

output "db_name" {
  description = "Application database name."
  value       = google_sql_database.app.name
}

output "runtime_service_account" {
  description = "Email of the Cloud Run runtime service account."
  value       = google_service_account.runtime.email
}

output "cloud_run_min_instances" {
  description = "Minimum Cloud Run instance count."
  value       = var.cloud_run_min_instances
}

output "cloud_run_max_instances" {
  description = "Maximum Cloud Run instance count."
  value       = var.cloud_run_max_instances
}

output "cloud_run_cpu" {
  description = "CPU allocation per Cloud Run instance."
  value       = var.cloud_run_cpu
}

output "cloud_run_memory" {
  description = "Memory allocation per Cloud Run instance."
  value       = var.cloud_run_memory
}

output "cloud_run_concurrency" {
  description = "Maximum concurrent requests per Cloud Run instance."
  value       = var.cloud_run_concurrency
}

output "cloud_run_timeout" {
  description = "Maximum request duration."
  value       = var.cloud_run_timeout
}

output "cloud_run_ingress" {
  description = "Cloud Run ingress setting."
  value       = var.cloud_run_ingress
}
