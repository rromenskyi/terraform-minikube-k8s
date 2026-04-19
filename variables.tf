variable "cluster_name" {
  description = "Name of the minikube cluster"
  type        = string
  default     = "tf-local"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,62}$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric with hyphens, max 63 characters."
  }
}

variable "driver" {
  description = "Minikube driver (docker, qemu, hyperkit, etc)"
  type        = string
  default     = "docker"
}

variable "cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 6
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 6144
}

variable "nodes" {
  description = "Number of nodes"
  type        = number
  default     = 1
}

variable "addons" {
  description = "List of minikube addons to enable. Ingress-related addons are intentionally absent — Traefik is installed via the sibling `terraform-k8s-addons` module."
  type        = list(string)
  default = [
    "dashboard",
    "default-storageclass",
    "storage-provisioner",
    "metrics-server",
  ]
}

variable "base_image" {
  description = "Base image for minikube"
  type        = string
  default     = "gcr.io/k8s-minikube/kicbase:v0.0.50"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the Minikube cluster (for example `v1.30.0` or `stable`)"
  type        = string
  default     = "stable"
}

variable "iso_urls" {
  description = "List of ISO URLs to try"
  type        = list(string)
  default = [
    "https://storage.googleapis.com/minikube/iso/minikube-v1.37.0-amd64.iso",
    "https://github.com/kubernetes/minikube/releases/download/v1.37.0/minikube-v1.37.0-amd64.iso",
  ]
}

# --------------------------------------------------------------------------
# Networking
# --------------------------------------------------------------------------

variable "service_cidr" {
  description = "CIDR range for Kubernetes Services (ClusterIP)"
  type        = string
  default     = "100.64.0.0/13"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "service_cidr must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  # NOTE: minikube's Flannel addon hardcodes "Network": "10.244.0.0/16" in its
  # kube-flannel-cfg ConfigMap and ignores kubeadm.pod-network-cidr. Setting
  # this to anything outside 10.244.0.0/16 causes Flannel to crash ("subnet
  # does not contain node PodCIDR") and leaves all new pods stuck in
  # ContainerCreating. Keep at 10.244.0.0/16 until the Flannel ConfigMap is
  # patched automatically during bootstrap to match the desired CGNAT range.
  # TODO: switch default to "100.72.0.0/13" once Flannel wiring is fixed.
  description = "CIDR range for Pods (if supported by CNI)"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "pod_cidr must be a valid CIDR block."
  }
}

variable "dns_ip" {
  description = "IP address for CoreDNS/kube-dns (must be inside service_cidr)"
  type        = string
  default     = "100.64.0.10"
}

variable "cni" {
  description = "CNI to use (bridge, calico, cilium, flannel, etc). Flannel is recommended on the macOS Docker driver."
  type        = string
  default     = "calico"
}

variable "apiserver_cert_extra_sans" {
  description = "Additional Subject Alternative Names embedded in the apiserver certificate. The default covers minikube's docker driver node IP (`192.168.49.2`). When using qemu / hyperkit / kvm2 / vmware, run `minikube ip -p <cluster>` after bootstrap and extend this list with the driver-specific node IP."
  type        = list(string)
  default     = ["localhost", "127.0.0.1", "10.0.0.1", "192.168.49.2"]
}
