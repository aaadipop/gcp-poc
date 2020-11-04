variable "env" {
  type    = string
}

variable "project_id" {}

variable "region" {
  type    = string
}

variable "network_name"{
  type    = string
}

variable "subnetwork_name"{
  type    = string
}

variable "machine_type" {
  default = "n1-standard-2"
  type    = string
}

variable "node_count" {
  default = 1
  type    = number
}

variable "disk_size_gb" {
  default = 10
  type    = number
}

variable "k8s_master_ip" {
  type    = string
}
