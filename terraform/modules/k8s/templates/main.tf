# if .yml file have changes the resource needs to be tainted
# before apply, run: terraform taint  module.k8s.module.k8s_templates.null_resource.k8s_services
resource "null_resource" "k8s_services" {
  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/services.yml apply"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/services.yml delete"
    interpreter   = ["/bin/bash", "-c"]
    when          = destroy
  }
}

# if .yml file have changes the resource needs to be tainted
# before apply, run: terraform taint  module.k8s.module.k8s_templates.null_resource.k8s_autoscale
resource "null_resource" "k8s_autoscale" {
  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/autoscale.yml apply"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/autoscale.yml delete"
    interpreter   = ["/bin/bash", "-c"]
    when          = destroy
  }
}

# if .yml file have changes the resource needs to be tainted
# before apply, run: terraform taint  module.k8s.module.k8s_templates.null_resource.k8s_logging
resource "null_resource" "k8s_logging" {
  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/fluentd.yml apply"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "kubectl -f ./modules/k8s/templates/fluentd.yml delete"
    interpreter   = ["/bin/bash", "-c"]
    when          = destroy
  }
}

resource "null_resource" "k8s_monitoring" {
  provisioner "local-exec" {
    command       = "kubectl create ns kube-monitoring"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "helm repo add stable https://kubernetes-charts.storage.googleapis.com"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "helm install prometheus stable/prometheus-operator --namespace kube-monitoring"
    interpreter   = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command       = "helm uninstall prometheus --namespace kube-monitoring" #--purge
    interpreter   = ["/bin/bash", "-c"]
    when          = destroy
  }
}
