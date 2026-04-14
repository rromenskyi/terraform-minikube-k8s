# cert-manager
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [kubernetes_namespace_v1.namespaces, helm_release.traefik]
}

# Let's Encrypt ClusterIssuers (Staging + Production)
resource "kubernetes_manifest" "cluster_issuer_staging" {
  count = var.enable_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
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

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer_production" {
  count = var.enable_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-production"
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

  depends_on = [helm_release.cert_manager]
}
