# Minikube Cluster definition
# This file is intentionally kept minimal and focused

resource "minikube_cluster" "this" {
  vm                 = true
  driver             = var.driver
  cluster_name       = var.cluster_name
  nodes              = var.nodes
  cpus               = var.cpus
  memory             = var.memory
  network            = "builtin"
  container_runtime  = "docker"
  base_image         = var.base_image
  kubernetes_version = var.kubernetes_version
  iso_url            = var.iso_urls

  # CNI is pinned to "false" and owned by this module's `flannel.tf` instead.
  # Minikube's `flannel` built-in addon hardcodes `"Network": "10.244.0.0/16"`
  # into its ConfigMap, IGNORES `kubeadm.pod-network-cidr`, and the resulting
  # 10.244.0.1 gateway collides with kicbase's bundled podman bridge
  # (`cni-podman0` same IP) — coredns/metrics-server get "no route to host"
  # on in-cluster Service NAT a few minutes into every bootstrap. Letting
  # Terraform own the Flannel manifest lets us render the subnet from
  # `var.pod_cidr` and escape 10.244 entirely.
  cni = "false"

  service_cluster_ip_range = var.service_cidr

  # Addons are kept minimal - Traefik and cert-manager are installed via Helm
  addons = var.addons

  extra_config = toset([
    # Pass the pod CIDR to kubeadm so the node object gets the right
    # `node.spec.podCIDR`. Our own Flannel manifest (flannel.tf) reads the
    # same value and renders `net-conf.json` accordingly, so the two
    # consumers of `var.pod_cidr` agree by construction.
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
      driver,
      nodes,
      cpus,
      memory,
    ]
  }
}

# Compose the cluster kubeconfig from the provider's outputs and drop it at
# a known path. Consumer modules (notably `terraform-k8s-addons`) read it
# via `config_path`, keeping the distribution-agnostic contract uniform
# across `terraform-minikube-k8s` and `terraform-k3s-k8s`.
resource "local_sensitive_file" "kubeconfig" {
  filename        = local.kubeconfig_path
  content         = local.kubeconfig_yaml
  file_permission = "0600"
}
