output "cluster_name" {
  description = "Name of the created minikube cluster"
  value       = var.cluster_name
}

output "cluster_distribution" {
  description = "Which Kubernetes distribution this module provisions. Lets consumer modules (e.g. `terraform-k8s-addons`) branch on distribution programmatically instead of hardcoding a source path."
  value       = "minikube"
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = minikube_cluster.this.host
}

output "client_certificate" {
  description = "Client certificate (PEM) for authentication"
  value       = minikube_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key (PEM) for authentication"
  value       = minikube_cluster.this.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (PEM)"
  value       = minikube_cluster.this.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Local path to the composed kubeconfig file for this cluster. Wire this into `module \"addons\" { kubeconfig_path = module.k8s.kubeconfig_path }` in the platform root. The value references `local_sensitive_file.kubeconfig.filename` (not the `local.kubeconfig_path` literal) so the Terraform dependency graph makes downstream consumers wait for the file to land on disk before they try to open it."
  value       = local_sensitive_file.kubeconfig.filename
}

output "kubeconfig_command" {
  description = "Shell command to export this cluster's kubeconfig for kubectl/helm"
  value       = "export KUBECONFIG='${local.kubeconfig_path}'"
}

output "addons" {
  description = "Enabled minikube addons"
  value       = var.addons
}

output "service_cidr" {
  description = "Configured Service CIDR"
  value       = var.service_cidr
}

output "pod_cidr" {
  description = "Configured Pod CIDR"
  value       = var.pod_cidr
}

output "dns_ip" {
  description = "CoreDNS IP address"
  value       = var.dns_ip
}

output "access_instructions" {
  description = "Helpful commands to interact with the cluster"
  value = {
    export_kubeconfig = "export KUBECONFIG='${local.kubeconfig_path}'"
    alternative       = "minikube -p ${var.cluster_name} kubeconfig get > ~/.kube/config"
    tunnel            = "optional: minikube -p ${var.cluster_name} tunnel  # only needed for LoadBalancer services"
    dashboard         = "minikube -p ${var.cluster_name} dashboard"
    get_pods          = "kubectl --kubeconfig '${local.kubeconfig_path}' get pods -A"
  }
}
