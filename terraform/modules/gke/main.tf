# https://github.com/richardalberto/terraform-google-kubernetes-istio/blob/master/main.tf

data "google_container_engine_versions" "gke_versions" {}

resource "random_id" "gke_cluster_random" {
  byte_length   = 2
}

resource "google_container_cluster" "gke_cluster" {
  provider                 = google
  name                     = "${var.project_id}-gke-cluster-${random_id.gke_cluster_random.hex}"
  location                 = var.region
  #min_master_version       = data.google_container_engine_versions.gke_versions.latest_master_version #"1.17.12-gke.500"

  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.network_name
  subnetwork               = var.subnetwork_name

  addons_config {

    http_load_balancing {
      disabled = false
    }

    # istio_config {
    #   disabled = true
    #   auth = "AUTH_MUTUAL_TLS"
    # }

  }

  cluster_autoscaling{
    enabled                     = true
    resource_limits {
      resource_type             = "cpu"
      minimum                   = "4"
      maximum                   = "10"
    }
    resource_limits {
      resource_type             = "memory"
      maximum                   = "64"
    }
  }

  master_auth {
    username                    = ""
    password                    = ""

    client_certificate_config {
      issue_client_certificate  = false
    }
  }

  lifecycle {
    create_before_destroy       = true    # when update, false if destroy
    ignore_changes              = [node_pool]
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block     = "/16"
    services_ipv4_cidr_block    = "/24"
  }

  # master_authorized_networks_config {
  #   cidr_blocks = [
  #     {
  #       cidr_block            = "${var.k8s_master_ip}/32"
  #     },
  #   ]
  # }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name}"
  }

  # https://www.hashicorp.com/blog/zero-downtime-updates-with-terraform
  # provisioner "local-exec" {
  #   command = "./check_health.sh ${self.ipv4_address}"
  # }
}

# https://registry.terraform.io/modules/baozuo/gke-node-pool/google/latest | zero downtime
module "gke-node-pool" {
  source      = "baozuo/gke-node-pool/google"
  project     = var.project_id
  cluster     = google_container_cluster.gke_cluster.name
  location    = var.region
  name_prefix = "${var.project_id}-gke-pool-${var.env}"
  version     = "0.1.3"

  # Most arguments are available under this section
  # https://www.terraform.io/docs/providers/google/r/container_node_pool.html
  config      = {
    # Optional configurations
    machine_type   = var.machine_type
    disk_size_gb   = var.disk_size_gb
    min_node_count = 3
    max_node_count = 10

    # have default
    # oauth_scopes = [
    #   "https://www.googleapis.com/auth/logging.write",
    #   "https://www.googleapis.com/auth/monitoring",
    #   "https://www.googleapis.com/auth/devstorage.read_only",
    # ]

    # default true
    # management = {
    #   auto_repair  = true
    #   auto_upgrade = true
    # }

  }
}

# old config
# resource "google_container_node_pool" "gke_pool" {
#   provider   = google
#   name       = "node-pool-${var.env}"
#   location   = var.region
#   cluster    = google_container_cluster.gke_cluster.name
#   node_count = var.node_count
#
#   node_config {
#     preemptible  = true
#     machine_type = var.machine_type
#     disk_size_gb = var.disk_size_gb
#
#     metadata = {
#       disable-legacy-endpoints = "true"
#     }
#
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#       "https://www.googleapis.com/auth/devstorage.read_only",
#     ]
#   }
#
#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }
#
#   autoscaling {
#     min_node_count = 3
#     max_node_count = 10
#   }
# }
