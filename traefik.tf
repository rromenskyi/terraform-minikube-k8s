# Traefik Ingress Controller
# Using for_each pattern instead of count for modern Terraform standards

resource "helm_release" "traefik" {
  for_each   = var.enable_traefik ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_version
  namespace        = "traefik"
  create_namespace = true

  # Core service configuration
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "ports.web.port"
    value = "80"
  }

  set {
    name  = "ports.websecure.port"
    value = "443"
  }

  set {
    name  = "ports.websecure.tls.enabled"
    value = "true"
  }

  # IngressClass configuration
  set {
    name  = "ingressClass.enabled"
    value = "true"
  }

  set {
    name  = "ingressClass.isDefaultClass"
    value = "true"
  }

  # Add common labels via values (if chart supports it)
  values = [
    yamlencode({
      commonLabels = local.common_labels
      ingressRoute = {
        dashboard = {
          enabled     = var.enable_traefik_dashboard
          entryPoints = ["web"]
          matchRule   = "Host(`traefik.localhost`)"
        }
      }
    })
  ]
}

# Explicit IngressClass
resource "kubernetes_ingress_class_v1" "traefik" {
  for_each   = var.enable_traefik ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  metadata {
    name   = "traefik"
    labels = local.common_labels
  }

  spec {
    controller = "traefik.io/ingress-controller"
  }
}
