# cert-manager with Let's Encrypt issuers
# Using for_each and common labels. No explicit depends_on - Terraform handles ordering.

resource "helm_release" "cert_manager" {
  for_each   = var.enable_cert_manager ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  # commonLabels is intentionally omitted: cert-manager's JSON Schema validation
  # rejects unknown top-level keys starting from v1.14.
}

# Let's Encrypt ClusterIssuers are installed through a small local Helm chart.
# This keeps first-run bootstrap safe because the Helm provider can plan the
# release before the Kubernetes API is reachable.
resource "helm_release" "cluster_issuers" {
  for_each   = var.enable_cert_manager ? toset(["enabled"]) : toset([])
  depends_on = [helm_release.cert_manager]

  name             = "cert-manager-cluster-issuers"
  chart            = "${path.module}/charts/cert-manager-cluster-issuers"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    yamlencode({
      commonLabels      = local.common_labels
      letsencrypt_email = var.letsencrypt_email
    })
  ]

  lifecycle {
    precondition {
      condition     = var.enable_traefik
      error_message = "Let's Encrypt ClusterIssuers require Traefik — the HTTP-01 solver template hardcodes ingress class 'traefik'. Set enable_traefik = true or disable cert-manager."
    }
  }
}
