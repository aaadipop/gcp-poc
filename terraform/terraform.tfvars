project_id         = "isv-294609"
credentials_file   = "isv-9b04b0547b4e.json"
region             = "europe-west4"
zone               = "europe-west4-a"
domain             = "isv.app"

k8s_master_ip      = "127.0.0.1"
node_count         = 3
machine_type       = "e2-medium"

db_replica_zone    = "europe-west4-c"

gcp_service_list = [
  "cloudresourcemanager.googleapis.com",
  "container.googleapis.com",
  "compute.googleapis.com",
  "sqladmin.googleapis.com",
  "servicenetworking.googleapis.com",
]
