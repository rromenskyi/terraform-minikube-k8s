# Common locals and labels used across all resources

locals {
  common_labels = {
    terraform   = "true"
    module      = "terraform-minikube-k8s"
    environment = "local"
    managed_by  = "terraform"
  }

  managed_namespaces = setunion(
    toset(var.namespaces),
    var.create_ops_workload && var.namespace != "default" ? toset([var.namespace]) : toset([])
  )

  # Common annotations if needed in future
  common_annotations = {
    "app.kubernetes.io/managed-by" = "terraform"
  }
}
