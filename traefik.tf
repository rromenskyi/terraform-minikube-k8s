# Traefik Ingress Controller
# Using for_each pattern instead of count for modern Terraform standards

resource "helm_release" "traefik" {
  for_each   = var.enable_traefik ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_version
  namespace        = "ingress-controller"
  create_namespace = true

  # Core service configuration
  # NodePort instead of LoadBalancer — Minikube does not provision cloud LBs.
  # External traffic reaches Traefik via Cloudflare Tunnel, not a LoadBalancer IP.
  set {
    name  = "service.type"
    value = "NodePort"
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

  # Relax readiness probe defaults — the chart ships with failureThreshold=1 and
  # initialDelaySeconds=2, which is too aggressive on fresh clusters with Calico CNI
  # where networking takes longer to converge.
  values = [
    yamlencode({
      commonLabels = local.common_labels
      ingressRoute = {
        dashboard = {
          enabled     = var.enable_traefik_dashboard
          entryPoints = ["web"]
          matchRule   = "Host(`traefik.${var.base_domain}`)"
        }
      }
      readinessProbe = {
        initialDelaySeconds = 15
        failureThreshold    = 5
        periodSeconds       = 10
        successThreshold    = 1
        timeoutSeconds      = 2
      }
      livenessProbe = {
        initialDelaySeconds = 15
        failureThreshold    = 5
        periodSeconds       = 10
        successThreshold    = 1
        timeoutSeconds      = 2
      }
    })
  ]

  timeout = 600
}
