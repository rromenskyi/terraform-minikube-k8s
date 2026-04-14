# Kubernetes Namespaces
# Using for_each for better readability and future extensibility

resource "kubernetes_namespace_v1" "namespaces" {
  for_each   = toset(var.namespaces)
  depends_on = [minikube_cluster.this]

  metadata {
    name   = each.key
    labels = local.common_labels
  }
}
