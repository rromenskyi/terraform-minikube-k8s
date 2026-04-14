# Kubernetes Namespaces
# Using for_each for better readability and future extensibility

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name   = each.key
    labels = local.common_labels
  }
}
