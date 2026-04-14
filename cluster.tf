# Minikube Cluster definition
# This file is intentionally kept minimal and focused

resource "minikube_cluster" "this" {
  vm                = true
  driver            = var.driver
  cluster_name      = var.cluster_name
  nodes             = var.nodes
  cpus              = var.cpus
  memory            = var.memory
  cni               = var.cni
  network           = "builtin"
  container_runtime = "docker"
  base_image        = var.base_image
  iso_url           = var.iso_urls

  # Addons are kept minimal - Traefik and cert-manager are installed via Helm
  addons = var.addons

  # Networking: using CGNAT range (100.64.0.0/10) to avoid conflicts with real networks
  extra_config = toset([
    "kubeadm.service-cluster-ip-range=${var.service_cidr}",
    "kubeadm.cluster-dns=${var.dns_ip}",
    "kubelet.cluster-dns=${var.dns_ip}",
  ])

  lifecycle {
    ignore_changes = [
      iso_url,
    ]
  }
}
