# This module owns cluster bootstrap AND Flannel CNI install. Everything
# else (Traefik, cert-manager, monitoring, workloads) belongs to
# `terraform-k8s-addons` and is configured there via `kubeconfig_path` from
# this module's outputs — we do NOT configure `kubernetes` / `helm`
# providers here.

provider "minikube" {
  # The provider incorrectly uses its own provider-level kubernetes_version
  # default during cluster creation instead of the resource attribute, so
  # we pin it here too.
  kubernetes_version = var.kubernetes_version
}

# The kubectl provider is configured from `minikube_cluster.this`'s attributes
# directly (rather than reading the file that `local_sensitive_file.kubeconfig`
# writes). Reason: referencing the resource attributes lets Terraform plan
# against an unborn cluster — no file-doesn't-exist errors on first apply,
# no ordering dance. `load_config_file = false` is load-bearing here; with
# `true` the provider would try to read a default-path kubeconfig at plan
# time and fail if the operator has no prior cluster.
provider "kubectl" {
  host                   = minikube_cluster.this.host
  client_certificate     = minikube_cluster.this.client_certificate
  client_key             = minikube_cluster.this.client_key
  cluster_ca_certificate = minikube_cluster.this.cluster_ca_certificate
  load_config_file       = false
}
