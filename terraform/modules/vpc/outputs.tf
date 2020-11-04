output "static_ip" {
  value = google_compute_global_address.ip_address.name
}

output "network_link" {
  value = google_compute_network.gke_network.self_link
}

output "subnetwork_link" {
  value = google_compute_subnetwork.gke_subnetwork.self_link
}

output "network_name" {
  value = google_compute_network.gke_network.name
}

output "subnetwork_name" {
  value = google_compute_subnetwork.gke_subnetwork.name
}
