# Monitoring stack (Prometheus + Grafana) using kube-prometheus-stack
# for_each pattern + common labels. No explicit depends_on.

resource "random_password" "grafana" {
  for_each   = var.enable_monitoring ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  length  = 16
  special = false
}

resource "helm_release" "monitoring" {
  for_each   = var.enable_monitoring ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "70.0.0" # Updated to newer version
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = random_password.grafana["enabled"].result
  }

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  # Grafana's chart-side ingress is left disabled on purpose. The Ingress
  # exposing grafana.localhost is managed below as `kubernetes_ingress_v1.grafana`,
  # which carries the Traefik-specific router annotations the chart would not.

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
  for_each   = var.enable_monitoring ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

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
