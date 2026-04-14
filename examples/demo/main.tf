terraform {
  required_version = ">= 1.5.0"
}

module "minikube" {
  source = "../../"

  cluster_name = "demo-cluster"
  cpus         = 4
  memory       = 6144
  cni          = "calico"

  service_cidr = "100.64.0.0/13"
  pod_cidr     = "100.72.0.0/13"
  dns_ip       = "100.64.0.10"

  namespaces           = ["apps", "monitoring"]
  enable_traefik            = true
  enable_traefik_dashboard  = true
  enable_cert_manager       = true
  enable_monitoring         = true
  letsencrypt_email         = "demo@example.com"
  # grafana password is randomly generated (see: terraform output grafana_credentials)
}

# Example application with Ingress + TLS
resource "kubernetes_deployment_v1" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = "apps"
    labels    = { app = "demo" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "demo" }
    }

    template {
      metadata {
        labels = { app = "demo" }
      }

      spec {
        container {
          name  = "app"
          image = "nginx:alpine"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = "apps"
  }

  spec {
    selector = { app = "demo" }
    port {
      port        = 80
      target_port = 80
    }
  }
}

# Certificate via cert-manager
resource "kubernetes_manifest" "demo_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "demo-tls"
      namespace = "apps"
    }
    spec = {
      secretName = "demo-tls"
      issuerRef = {
        name = "letsencrypt-staging"
        kind = "ClusterIssuer"
      }
      dnsNames = ["demo.localhost"]
    }
  }
}

# Ingress with TLS
resource "kubernetes_ingress_v1" "demo_ingress" {
  metadata {
    name      = "demo-ingress"
    namespace = "apps"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = "demo.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "demo-app"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      secret_name = "demo-tls"
      hosts       = ["demo.localhost"]
    }
  }

  depends_on = [kubernetes_manifest.demo_certificate]
}

output "demo_urls" {
  value = {
    app_url           = "https://demo.localhost"
    traefik_url       = "http://traefik.localhost"
    traefik_dashboard = "http://traefik.localhost/dashboard/"
    grafana_url   = "https://grafana.localhost"
    note          = "Run: minikube -p demo-cluster tunnel. Password: terraform output -json grafana_credentials | jq -r '.value.password'"
  }
}

output "module_outputs" {
  value = module.minikube.access_instructions
}
