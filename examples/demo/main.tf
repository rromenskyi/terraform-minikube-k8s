terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  host                   = module.minikube.cluster_host
  client_certificate     = module.minikube.client_certificate
  client_key             = module.minikube.client_key
  cluster_ca_certificate = module.minikube.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.minikube.cluster_host
    client_certificate     = module.minikube.client_certificate
    client_key             = module.minikube.client_key
    cluster_ca_certificate = module.minikube.cluster_ca_certificate
  }
}

module "minikube" {
  source = "../../"

  cluster_name = "demo-cluster"
  cpus         = 4
  memory       = 6144
  cni          = "flannel"

  service_cidr = "100.64.0.0/13"
  pod_cidr     = "100.72.0.0/13"
  dns_ip       = "100.64.0.10"

  namespaces               = ["apps", "monitoring"]
  enable_traefik           = true
  enable_traefik_dashboard = true
  enable_cert_manager      = true
  enable_monitoring        = true
  letsencrypt_email        = "demo@example.com"
  # grafana password is randomly generated (see: terraform output grafana_credentials)
}

# Example application with Ingress + TLS
resource "kubernetes_deployment_v1" "demo_app" {
  depends_on = [module.minikube]

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
  depends_on = [module.minikube]

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

# Certificate via cert-manager, rendered through a tiny local Helm chart
resource "helm_release" "demo_certificate" {
  depends_on = [module.minikube]

  name             = "demo-certificate"
  chart            = "${path.module}/charts/demo-certificate"
  namespace        = "apps"
  create_namespace = true
}

# Ingress with TLS
resource "kubernetes_ingress_v1" "demo_ingress" {
  depends_on = [helm_release.demo_certificate]

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

}

output "demo_urls" {
  value = {
    app_url           = "https://demo.localhost"
    traefik_url       = "http://traefik.localhost"
    traefik_dashboard = "http://traefik.localhost/dashboard/"
    grafana_url       = "https://grafana.localhost"
    note              = "For standalone access, expose Traefik for your driver first. Password: terraform output -json grafana_credentials | jq -r '.value.password'"
  }
}

output "module_outputs" {
  value = module.minikube.access_instructions
}
