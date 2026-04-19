terraform {
  required_version = ">= 1.5.0"
}

# Minimal minikube cluster bootstrap. The module starts a minikube profile
# and exposes its kubeconfig at `module.minikube.kubeconfig_path`. The addon
# layer (Traefik, cert-manager, kube-prometheus-stack, ...) lives in the
# sibling `terraform-k8s-addons` module — compose it on top by consuming
# `kubeconfig_path`.
module "minikube" {
  source = "../../"

  cluster_name = "dev"
  cpus         = 6
  memory       = 8192
  driver       = "docker"

  addons = [
    "dashboard",
    "metrics-server",
    "storage-provisioner"
  ]
}

output "kubeconfig_path" {
  value = module.minikube.kubeconfig_path
}

output "cluster_info" {
  value = {
    name         = module.minikube.cluster_name
    distribution = module.minikube.cluster_distribution
    host         = module.minikube.cluster_host
    addons       = module.minikube.addons
  }
}
