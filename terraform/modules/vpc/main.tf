# Public static ip
resource "google_compute_global_address" "ip_address" {
  name = "${var.project_id}-static-ip"
}

# share this network with db
resource "google_compute_network" "gke_network" {
  provider                = google
  name                    = "${var.project_id}-gke-cluster-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "${var.project_id}-gke-cluster-subnetwork-${var.env}"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.gke_network.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall
resource "google_compute_firewall" "firewall-local" {
  name          = "${var.project_id}-firewall-local"
  network       = google_compute_network.gke_network.name

  allow {
    protocol    = "icmp"
  }

  allow {
    protocol    = "tcp"
  }

  allow {
    protocol    = "udp"
  }

  source_ranges = [google_compute_subnetwork.gke_subnetwork.ip_cidr_range]
}

resource "google_compute_firewall" "firewall-public" {
  name          = "${var.project_id}-firewall-public"
  network       = google_compute_network.gke_network.name

  allow {
    protocol    = "icmp"
  }

  allow {
    protocol    = "tcp"
    ports       = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# DNS
# resource "google_dns_managed_zone" "default" {
#   name     = "default-zone"
#   dns_name = var.domain
# }
#
# resource "google_dns_record_set" "default" {
#   name         = google_dns_managed_zone.default.dns_name
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.default.name
#   rrdatas      = [google_compute_global_address.ip_address.address]
# }
