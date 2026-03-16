resource "google_storage_bucket" "tf_state" {
  project  = google_project.this.project_id
  name     = "${var.project_id}-tf-state"
  location = var.region

  force_destroy = false

  versioning {
    enabled = true
  }
  
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

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  autoclass {
    enabled = true
  }

  depends_on = [google_project_service.apis]
}