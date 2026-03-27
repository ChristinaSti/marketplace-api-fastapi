# =============================================================================
# Private VPC network for Cloud Run and Cloud SQL.
# Cloud Run connects via a Serverless VPC Access connector;
# Cloud SQL connects via Private Service Access (VPC peering).
# All inbound traffic is denied explicitly to maintain an audit trail.
# =============================================================================

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${var.service_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC for ${var.service_name}: Cloud Run and Cloud SQL."
}

resource "google_compute_subnetwork" "connector" {
  project                  = var.project_id
  name                     = "${var.service_name}-connector-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.0.0.0/28"
  private_ip_google_access = true
}

resource "google_vpc_access_connector" "main" {
  project = var.project_id
  name    = "${var.service_name}-connector"
  region  = var.region

  subnet {
    name = google_compute_subnetwork.connector.name
  }

  machine_type   = "e2-micro"
  min_throughput = 200
  max_throughput = 1000
}

resource "google_compute_global_address" "private_services" {
  project       = var.project_id
  name          = "${var.service_name}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.1.0.0"
  prefix_length = 20
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# explicit deny-all ingress adds logging to the same but silent rule by GCP on 
# priority 65535
resource "google_compute_firewall" "deny_all_ingress" {
  project   = var.project_id
  name      = "${var.service_name}-deny-all-ingress"
  network   = google_compute_network.main.name
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
