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
  description = "List of minikube addons to enable"
  type        = list(string)
  default = [
    "dashboard",
    "default-storageclass",
    "storage-provisioner",
    "metrics-server"
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
    "https://github.com/kubernetes/minikube/releases/download/v1.37.0/minikube-v1.37.0-amd64.iso"
  ]
}

variable "create_ops_workload" {
  description = "Whether to create the ops StatefulSet workload"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace for the optional ops workload"
  type        = string
  default     = "ops"
}

variable "ops_image" {
  description = "Image to use for the ops workload"
  type        = string
  default     = "alpine:3.20"
}

variable "ops_storage_class_name" {
  description = "StorageClass used by the ops StatefulSet's PVC. Default matches minikube's `default-storageclass` addon. If you drop that addon, either pin this to a StorageClass you install yourself or set this to `null` to rely on an externally-configured cluster default."
  type        = string
  default     = "standard"
}

# Networking
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
  description = "CIDR range for Pods (if supported by CNI)"
  type        = string
  default     = "100.72.0.0/13"

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

# Advanced configuration
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

variable "namespaces" {
  description = "List of additional namespaces to create"
  type        = list(string)
  default     = ["ops", "monitoring"]
}

variable "namespace_pod_security_level" {
  description = "Pod Security Standards level applied to module-managed namespaces (enforce + audit + warn). `baseline` is a safe default for most workloads. `restricted` is the strictest and may break Helm charts that require privileged pods (kube-prometheus-stack's node-exporter, for example). `privileged` effectively disables enforcement."
  type        = string
  default     = "baseline"

  validation {
    condition     = contains(["privileged", "baseline", "restricted"], var.namespace_pod_security_level)
    error_message = "namespace_pod_security_level must be one of: privileged, baseline, restricted."
  }
}

variable "enable_namespace_limits" {
  description = "Apply a default `ResourceQuota` and `LimitRange` to each module-managed namespace. Disable only if you enforce quotas out-of-band."
  type        = bool
  default     = true
}

variable "base_domain" {
  description = "Base domain used to derive default hostnames for Traefik dashboard (`traefik.<base>`) and Grafana (`grafana.<base>`). Defaults to `localhost` for local minikube usage; set to a real domain (e.g. `dev.example.com`) for remote access."
  type        = string
  default     = "localhost"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", var.base_domain))
    error_message = "base_domain must be a valid DNS label sequence (lowercase alphanumerics, dots, hyphens)."
  }
}

variable "enable_traefik" {
  description = "Deploy Traefik as Ingress controller via Helm"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Deploy cert-manager + Let's Encrypt ClusterIssuers"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt registration (required for cert-manager). Must be a real mailbox — Let's Encrypt rate-limits RFC-2606 reserved domains (example.com, example.org, example.net, example.invalid, test, localhost) and does not issue certificates to them."
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.letsencrypt_email))
    error_message = "letsencrypt_email must be a valid email address."
  }

  validation {
    condition     = !can(regex("@(example\\.(com|org|net|invalid)|test|localhost)$", var.letsencrypt_email))
    error_message = "letsencrypt_email must not use an RFC-2606 reserved domain (example.com, example.org, example.net, example.invalid, test, localhost) — Let's Encrypt rejects those."
  }
}

variable "traefik_version" {
  description = "Traefik Helm chart version"
  type        = string
  default     = "34.2.0"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.16.1"
}

variable "kube_prometheus_stack_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "70.0.0"
}

variable "enable_traefik_dashboard" {
  description = "Expose Traefik dashboard via IngressRoute"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Deploy Prometheus + Grafana via kube-prometheus-stack"
  type        = bool
  default     = true
}

# Validation blocks (added to original variable definitions above)
