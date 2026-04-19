# After the addon layer was extracted into the sibling `terraform-k8s-addons`
# module, this module no longer creates any Kubernetes or Helm resources —
# it only runs the `minikube` provider and writes a composed kubeconfig
# with `local_sensitive_file`. The kubernetes/helm providers were removed;
# the consumer (typically `terraform-k8s-addons`) configures them itself
# using `kubeconfig_path` from this module's outputs.

provider "minikube" {
  # The provider incorrectly uses its own provider-level kubernetes_version
  # default during cluster creation instead of the resource attribute, so
  # we pin it here too.
  kubernetes_version = var.kubernetes_version
}
