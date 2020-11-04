locals {
  env = "prod"
}

# resource "google_project_service" "gcp_services" {
#   count   = length(var.gcp_service_list)
#   project = var.project_id
#   service = var.gcp_service_list[count.index]
#
#   disable_dependent_services = true
# }

module "vpc" {
  source = "./modules/vpc"

  env                   = local.env
  project_id            = var.project_id
  region                = var.region
  domain                = var.domain
}

module "gke" {
  source = "./modules/gke"

  depends_on            = [module.vpc]

  env                   = local.env
  project_id            = var.project_id
  region                = var.region

  network_name          = module.vpc.network_name
  subnetwork_name       = module.vpc.subnetwork_name

  k8s_master_ip         = var.k8s_master_ip
  machine_type          = var.machine_type
  node_count            = var.node_count
}

module "sql" {
  source = "./modules/sql"

  depends_on            = [module.vpc]

  env                   = local.env
  project_id            = var.project_id
  region                = var.region

  network               = module.vpc.network_link
  db_zone               = var.zone
  db_replica_zone       = var.db_replica_zone
}

module "k8s" {
  source = "./modules/k8s"

  depends_on            = [module.gke]

  namespace             = local.env
  public_ip             = module.vpc.static_ip

  db_name               = module.sql.db_name
  db_user               = module.sql.db_user
  db_pass               = module.sql.db_pass
  db_host               = module.sql.db_host
}
