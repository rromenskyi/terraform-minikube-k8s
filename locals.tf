# Common locals and labels used across all resources

locals {
  common_labels = {
    terraform   = "true"
    module      = "terraform-minikube-platform"
    environment = "local"
    managed_by  = "terraform"
  }

  # Common annotations if needed in future
  common_annotations = {
    "app.kubernetes.io/managed-by" = "terraform"
  }
}
