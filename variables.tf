variable "cluster_name" {
  description = "Name of the minikube cluster"
  type        = string
  default     = "tf-local"
}

variable "driver" {
  description = "Minikube driver (docker, qemu, hyperkit, etc)"
  type        = string
  default     = "docker"
}

variable "cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
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
    "ingress",
    "storage-provisioner",
    "metrics-server"
  ]
}

variable "base_image" {
  description = "Base image for minikube"
  type        = string
  default     = "gcr.io/k8s-minikube/kicbase:v0.0.48"
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
  description = "Kubernetes namespace for workloads"
  type        = string
  default     = "default"
}

variable "ops_image" {
  description = "Image to use for the ops workload"
  type        = string
  default     = "alpine:3.20"
}

# Networking
variable "service_cidr" {
  description = "CIDR range for Kubernetes Services (ClusterIP)"
  type        = string
  default     = "100.64.0.0/13"
}

variable "pod_cidr" {
  description = "CIDR range for Pods (if supported by CNI)"
  type        = string
  default     = "100.72.0.0/13"
}

variable "dns_ip" {
  description = "IP address for CoreDNS/kube-dns (must be inside service_cidr)"
  type        = string
  default     = "100.64.0.10"
}

# Advanced configuration
variable "cni" {
  description = "CNI to use (bridge, calico, cilium, flannel, etc). Calico recommended for better ingress support."
  type        = string
  default     = "calico"
}

variable "namespaces" {
  description = "List of additional namespaces to create"
  type        = list(string)
  default     = ["ops", "monitoring"]
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
  description = "Email for Let's Encrypt registration (required for cert-manager)"
  type        = string
  default     = "admin@example.com"
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

variable "enable_traefik_dashboard" {
  description = "Expose Traefik dashboard via IngressRoute"
  type        = bool
  default     = true
}

# Backend configuration (Backblaze B2 / S3 compatible)
variable "backend_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "tfstate-unique"
}

variable "backend_key" {
  description = "Path to state file in bucket"
  type        = string
  default     = "dev/terraform-minikube.tfstate"
}

variable "backend_region" {
  description = "Region for S3 backend"
  type        = string
  default     = "us-east-1"
}

variable "backend_endpoint" {
  description = "S3-compatible endpoint (Backblaze B2)"
  type        = string
  default     = "https://s3.us-east-005.backblazeb2.com"
}

variable "enable_monitoring" {
  description = "Deploy Prometheus + Grafana via kube-prometheus-stack"
  type        = bool
  default     = true
}
