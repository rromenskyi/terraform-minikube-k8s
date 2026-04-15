terraform {
  required_version = ">= 1.5.0"
}

module "minikube" {
  source = "../../"

  cluster_name = "my-dev-cluster"
  cpus         = 6
  memory       = 8192
  driver       = "docker"

  addons = [
    "dashboard",
    "ingress",
    "metrics-server",
    "storage-provisioner"
  ]

  create_ops_workload = true
  ops_image           = "nginx:alpine"
  namespace           = "ops"

  # Use 100.64.0.0/10 CGNAT range to avoid conflicts with home/office networks
  service_cidr = "100.64.0.0/13"
  pod_cidr     = "100.72.0.0/13"
  dns_ip       = "100.64.0.10"

  cni            = "calico" # better than bridge for ingress
  namespaces     = ["ops", "monitoring", "apps"]
  enable_traefik = true
}

output "kubeconfig_path" {
  value = module.minikube.kubeconfig_path
}

output "get_kubeconfig_cmd" {
  value = module.minikube.kubeconfig_command
}

output "cluster_info" {
  value = {
    name    = module.minikube.cluster_name
    host    = module.minikube.cluster_host
    addons  = module.minikube.addons
    ops_pod = module.minikube.ops_statefulset_name
  }
}
