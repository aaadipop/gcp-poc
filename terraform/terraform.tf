terraform {

  required_version  = "0.13.4"

  backend "gcs" {
    credentials     = "./isv-9b04b0547b4e.json"
    bucket          = "terraform-gstate-isv"
    prefix          = "terraform/state"
  }

  required_providers {
    google = {
      source          = "hashicorp/google"
      version         = "3.44.0"
    }

    google-beta = {
      source          = "hashicorp/google-beta"
      version         = "3.44.0"
    }

    kubernetes = {
      source        = "hashicorp/kubernetes"
      version       = "1.13.2"
    }

    kubectl = {
      source          = "gavinbunney/kubectl"
      version         = "1.9.1"
    }
  }
}
