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
  description = "CIDR range for Kubernetes Services (ClusterIP). Defaults to a /20 slice of the RFC 6598 CGNAT space (100.64.0.0/10) — 4094 IPs, ample for a single-node test cluster, and cleanly disjoint from RFC 1918 ranges any host networking might be using."
  type        = string
  default     = "100.64.0.0/20"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "service_cidr must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR range for Pods, written into Flannel's `net-conf.json` (see flannel.tf). Defaults to `100.72.0.0/16` — a /16 in the RFC 6598 CGNAT space (100.64.0.0/10), matching both the idiom `size-of-a-big-cluster pod range` (65k IPs, 256 possible /24 per-node slices × 254 pods each) and the 100.72.x.x family that `terraform-k3s-k8s` uses by default, so the two cluster modules speak the same IP vocabulary. Critically, the default is NOT 10.244.0.0/16 — kicbase's bundled podman network claims 10.244.0.1/16 and the collision breaks in-cluster Service NAT within minutes of bootstrap."
  type        = string
  default     = "100.72.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "pod_cidr must be a valid CIDR block."
  }
}

variable "dns_ip" {
  description = "IP address for CoreDNS/kube-dns (must be inside service_cidr)."
  type        = string
  default     = "100.64.0.10"
}

variable "flannel_version" {
  description = "Flannel release to pull the installation manifest from (https://github.com/flannel-io/flannel/releases). The module fetches `kube-flannel.yml` at this tag, rewrites the hardcoded 10.244.0.0/16 in the bundled ConfigMap to `var.pod_cidr`, and applies every document via the kubectl provider."
  type        = string
  default     = "v0.26.7"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.flannel_version))
    error_message = "flannel_version must be a semver tag like `v0.26.7`."
  }
}

variable "apiserver_cert_extra_sans" {
  description = "Additional Subject Alternative Names embedded in the apiserver certificate. The default covers minikube's docker driver node IP (`192.168.49.2`). When using qemu / hyperkit / kvm2 / vmware, run `minikube ip -p <cluster>` after bootstrap and extend this list with the driver-specific node IP."
  type        = list(string)
  default     = ["localhost", "127.0.0.1", "10.0.0.1", "192.168.49.2"]
}
