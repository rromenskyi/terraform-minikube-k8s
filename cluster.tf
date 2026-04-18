# Minikube Cluster definition
# This file is intentionally kept minimal and focused

resource "minikube_cluster" "this" {
  vm                 = true
  driver             = var.driver
  cluster_name       = var.cluster_name
  nodes              = var.nodes
  cpus               = var.cpus
  memory             = var.memory
  cni                = var.cni
  network            = "builtin"
  container_runtime  = "docker"
  base_image         = var.base_image
  kubernetes_version = var.kubernetes_version
  iso_url            = var.iso_urls

  # Addons are kept minimal - Traefik and cert-manager are installed via Helm
  addons = var.addons

  # Networking: using CGNAT range (100.64.0.0/10) to avoid conflicts with real networks
  extra_config = toset([
    "kubeadm.service-cluster-ip-range=${var.service_cidr}",
    "kubeadm.cluster-dns=${var.dns_ip}",
    "kubelet.cluster-dns=${var.dns_ip}",
    "kubeadm.apiserver-cert-extra-sans=localhost,127.0.0.1,10.0.0.1,192.168.49.2",
  ])

  lifecycle {
    # The minikube provider marks the attributes below as force-new, so editing
    # any of them in a running cluster would silently trigger destroy+recreate
    # and wipe workloads. Ignore drift here; reshaping these requires explicit
    # `terraform taint minikube_cluster.this` followed by `terraform apply`, or
    # `terraform destroy` + fresh apply. This is a deliberate "fail loud"
    # guardrail, not laziness.
    ignore_changes = [
      iso_url,
      addons,
      base_image,
      kubernetes_version,
      extra_config,
      cni,
      driver,
      nodes,
      cpus,
      memory,
    ]
  }
}
