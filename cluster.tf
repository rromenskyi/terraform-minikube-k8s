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

  service_cluster_ip_range = var.service_cidr

  # Addons are kept minimal - Traefik and cert-manager are installed via Helm
  addons = var.addons

  # Networking: using CGNAT range (100.64.0.0/10) to avoid conflicts with real networks
  extra_config = toset([
    # kubeadm.pod-network-cidr sets node.spec.podCIDR on the node object, but the
    # minikube Flannel addon hardcodes "Network": "10.244.0.0/16" in its ConfigMap
    # and does not read this value. Until the bootstrap patches the Flannel
    # net-conf to match, pod_cidr MUST stay at "10.244.0.0/16" or Flannel crashes.
    # TODO: patch kube-flannel-cfg ConfigMap in bootstrap Step 1.5 before Step 2,
    # then switch to CGNAT "100.72.0.0/13" (module) / "100.80.0.0/12" (platform).
    "kubeadm.pod-network-cidr=${var.pod_cidr}",
    "kubeadm.service-cluster-ip-range=${var.service_cidr}",
    "kubeadm.cluster-dns=${var.dns_ip}",
    # kicbase has losetup, but kubeadm preflight can still falsely report it
    # missing under the docker driver on newer Kubernetes/minikube combinations.
    "kubeadm.ignore-preflight-errors=FileExisting-losetup",
    "kubelet.cluster-dns=${var.dns_ip}",
    "kubeadm.apiserver-cert-extra-sans=${join(",", var.apiserver_cert_extra_sans)}",
  ])

  lifecycle {
    # The minikube provider marks the attributes below as force-new, so editing
    # any of them in a running cluster would silently trigger destroy+recreate
    # and wipe workloads. Ignore drift here; reshaping these requires explicit
    # `terraform taint minikube_cluster.this` followed by `terraform apply`, or
    # `terraform destroy` + fresh apply. This is a deliberate "fail loud"
    # guardrail, not laziness.
    ignore_changes = [
      # Minikube/provider may normalize the configured image reference to a
      # different canonical form in state (for example docker.io + digest),
      # which would otherwise force a full cluster replacement on plan.
      base_image,
      iso_url,
      addons,
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
