# This file is committed to version control to be used in CD pipeline by Terraform. 
# Do not add any sensitive values. 
# See variables.tf for production-tier recommendations to adapt the values as needed.

# ── Cloud SQL ────────────────────
postgres_version     = "POSTGRES_18"
db_machine_type      = "db-f1-micro"
db_availability_type = "ZONAL"
db_disk_size_gb      = 10
db_name              = "marketplace"

# ── Cloud Run ────────────────────
cloud_run_min_instances = 0
cloud_run_max_instances = 3
cloud_run_cpu           = "1"
cloud_run_memory        = "512Mi"
cloud_run_concurrency   = 80
cloud_run_timeout       = "60s"
cloud_run_ingress       = "all"
