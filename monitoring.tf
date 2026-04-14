# Monitoring stack (Prometheus + Grafana) using kube-prometheus-stack
# for_each pattern + common labels. No explicit depends_on.

resource "random_password" "grafana" {
  for_each = var.enable_monitoring ? toset(["enabled"]) : toset([])

  length  = 16
  special = false
}

resource "helm_release" "monitoring" {
  for_each = var.enable_monitoring ? toset(["enabled"]) : toset([])

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "70.0.0" # Updated to newer version
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

  # Better ServiceMonitor handling
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Reasonable resources for local Minikube
  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  values = [
    yamlencode({
      commonLabels = local.common_labels
      grafana = {
        sidecar = {
          dashboards = {
            enabled = true
          }
        }
      }
    })
  ]
}

# Additional Traefik-specific Ingress for Grafana (using kubernetes_ingress_v1 for compatibility)
resource "kubernetes_ingress_v1" "grafana" {
  for_each = var.enable_monitoring ? toset(["enabled"]) : toset([])

  metadata {
    name      = "grafana"
    namespace = "monitoring"
    labels    = local.common_labels
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
}
