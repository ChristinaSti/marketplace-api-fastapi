resource "google_storage_bucket" "tf_state" {
  project  = google_project.this.project_id
  name     = "${var.project_id}-tf-state"
  location = var.region

  force_destroy = false

  versioning {
    enabled = true
  }

  # Prevent accidental deletion for compliance: locks objects for a period
  retention_policy {
      retention_period = 604800  # in seconds = 1 day (minimum) 
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Keep only the 5 most recent state versions
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  # STANDARD: lowest latency, highest cost. 
  # For data accessed ~1x/month, use "NEARLINE" for cost savings
  storage_class = "STANDARD"  
  
  # Automatically transition to cheaper storage classes over time  if state changes infrequently
  autoclass {
    enabled = true
  } 

  depends_on = [google_project_service.apis]
}