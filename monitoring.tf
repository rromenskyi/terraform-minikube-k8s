# Generate random password for Grafana
resource "random_password" "grafana" {
  count   = var.enable_monitoring ? 1 : 0
  length  = 16
  special = false
}

# Monitoring stack: Prometheus + Grafana (kube-prometheus-stack)
resource "helm_release" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "68.1.1"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = random_password.grafana[0].result
  }

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "traefik"
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = "grafana.localhost"
  }

  set {
    name  = "grafana.ingress.tls[0].hosts[0]"
    value = "grafana.localhost"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Increase resources a bit for local Minikube
  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  depends_on = [
    kubernetes_namespace_v1.namespaces,
    helm_release.traefik,
    helm_release.cert_manager
  ]
}

# Grafana Ingress (additional config for Traefik)
resource "kubernetes_ingress_v1" "grafana" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "grafana"
    namespace = "monitoring"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = "grafana.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.monitoring]
}
