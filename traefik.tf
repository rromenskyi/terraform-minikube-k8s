# Traefik Ingress Controller
resource "helm_release" "traefik" {
  count = var.enable_traefik ? 1 : 0

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_version
  namespace        = "traefik"
  create_namespace = true

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

  set {
    name  = "ingressClass.enabled"
    value = "true"
  }

  set {
    name  = "ingressClass.isDefaultClass"
    value = "true"
  }

  depends_on = [kubernetes_namespace_v1.namespaces]
}

# Traefik Dashboard (via IngressRoute)
resource "kubernetes_manifest" "traefik_dashboard" {
  count = var.enable_traefik && var.enable_traefik_dashboard ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = "traefik"
    }
    spec = {
      entryPoints = ["web"]
      routes = [{
        match = "Host(`traefik.localhost`)"
        kind  = "Rule"
        services = [{
          name = "api@internal"
          kind = "TraefikService"
        }]
      }]
    }
  }

  depends_on = [helm_release.traefik]
}

# Traefik IngressClass
resource "kubernetes_ingress_class_v1" "traefik" {
  count = var.enable_traefik ? 1 : 0

  metadata {
    name = "traefik"
  }

  spec {
    controller = "traefik.io/ingress-controller"
  }
}
