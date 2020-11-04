variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
}

variable "zone" {
  type    = string
}

variable "credentials_file" {
  type    = string
}

variable "domain" {
  type    = string
}

variable "gcp_service_list" {
  type        = list
}

// gke
variable "k8s_master_ip" {
  type    = string
}

variable "machine_type" {
  type    = string
}

variable "node_count" {
  type    = number
}

// sql
variable "db_replica_zone" {
  type    = string
}
