resource "kubernetes_namespace" "namespace" {
  metadata {
    name        = var.namespace

    labels = {
      app       = "isv-app"
    }
  }
}

resource "kubernetes_config_map" "web-cm" {
  metadata {
    name        = "web-cm"
    namespace   = kubernetes_namespace.namespace.id
  }

  data = {
    PORT                 = 8080
  }
}

resource "kubernetes_config_map" "api-cm" {
  metadata {
    name        = "api-cm"
    namespace   = kubernetes_namespace.namespace.id
  }

  data = {
    PORT                 = 8000
    DB                   = var.db_name
    DBUSER               = var.db_user
    DBHOST               = var.db_host
    DBPORT               = 5432

  }
}

resource "kubernetes_secret" "api-secret" {
  metadata {
    name        = "api-secret"
    namespace   = kubernetes_namespace.namespace.id
  }

  data = {
    DBPASS               = var.db_pass
  }

}

resource "kubernetes_ingress" "ingress" {
  metadata {
    name        = "app-ingress"
    namespace   = kubernetes_namespace.namespace.id

    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = var.public_ip,
      # "nginx.ingress.kubernetes.io/rewrite-target"  = "/$1"
    }
  }

  spec {
    backend {
      service_name       = "web-service"
      service_port       = 80
    }

    rule {
      host               = "isv.app"

      http {
        path {
          backend {
            service_name = "web-service"
            service_port = 80
          }

          path           = "/*"
        }

        path {
          backend {
            service_name = "api-service"
            service_port = 80
          }

          path           = "/api/*"
        }
      }
    }

    rule {
      host               = "cannary.isv.app"

      http {
        path {
          backend {
            service_name = "web-service-cannary"
            service_port = 80
          }

          path           = "/*"
        }

        path {
          backend {
            service_name = "api-service-cannary"
            service_port = 80
          }

          path           = "/api/*"
        }
      }
    }

  }
}

module "k8s_templates" {
  source        = "./templates"

  depends_on    = [kubernetes_namespace.namespace]
}
