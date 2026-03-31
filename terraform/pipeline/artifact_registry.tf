# =============================================================================
# Artifact Registry Docker repository with cleanup policies to prevent
# unbounded storage growth.
# =============================================================================

locals {
  days_90 = "${90 * 24 * 60 * 60}s"
  days_7  = "${7 * 24 * 60 * 60}s"
}

resource "google_artifact_registry_repository" "api" {
  repository_id = var.service_name
  location      = var.region
  format        = "DOCKER"
  description   = "Docker images for ${var.service_name}"
  labels        = var.labels

  lifecycle {
    prevent_destroy = true
  }

  cleanup_policies {
    id     = "delete-old-tagged"
    action = "DELETE"
    condition {
      older_than = local.days_90
      tag_state  = "TAGGED"
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      older_than = local.days_7
      tag_state  = "UNTAGGED"
    }
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}
