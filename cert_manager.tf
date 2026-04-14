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

  values = [
    yamlencode({
      commonLabels = local.common_labels
    })
  ]
}

# Let's Encrypt ClusterIssuer - Staging
resource "kubernetes_manifest" "cluster_issuer_staging" {
  for_each   = var.enable_cert_manager ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = "letsencrypt-staging"
      labels = local.common_labels
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-staging-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "traefik"
            }
          }
        }]
      }
    }
  }
}

# Let's Encrypt ClusterIssuer - Production
resource "kubernetes_manifest" "cluster_issuer_production" {
  for_each   = var.enable_cert_manager ? toset(["enabled"]) : toset([])
  depends_on = [minikube_cluster.this]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = "letsencrypt-production"
      labels = local.common_labels
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-production-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "traefik"
            }
          }
        }]
      }
    }
  }
}
