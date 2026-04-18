output "cluster_name" {
  description = "Name of the created minikube cluster"
  value       = var.cluster_name
}

output "cluster_distribution" {
  description = "Which Kubernetes distribution this module provisions. Lets sibling-module consumers branch on distribution programmatically instead of hardcoding the source path."
  value       = "minikube"
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = minikube_cluster.this.host
}

output "client_certificate" {
  description = "Client certificate for authentication"
  value       = minikube_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key for authentication"
  value       = minikube_cluster.this.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = minikube_cluster.this.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Typical path to the kubeconfig file"
  value       = "~/.kube/config"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for this cluster"
  value       = "minikube -p ${var.cluster_name} kubeconfig get"
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

output "ops_statefulset_name" {
  description = "Name of the ops StatefulSet (if created)"
  value       = var.create_ops_workload ? kubernetes_stateful_set_v1.ops["enabled"].metadata[0].name : null
}

output "namespaces" {
  description = "Created namespaces"
  value       = [for ns in kubernetes_namespace_v1.namespaces : ns.metadata[0].name]
}

output "traefik_enabled" {
  description = "Whether Traefik is enabled"
  value       = var.enable_traefik
}

output "cert_manager_enabled" {
  description = "Whether cert-manager is enabled"
  value       = var.enable_cert_manager
}

output "monitoring_enabled" {
  description = "Whether Prometheus + Grafana stack is enabled"
  value       = var.enable_monitoring
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_monitoring ? "https://grafana.${var.base_domain}" : null
}

output "grafana_credentials" {
  description = "Grafana login credentials (password is randomly generated and stored in Terraform state)"
  value = var.enable_monitoring ? {
    url      = "https://grafana.${var.base_domain}"
    username = "admin"
    password = random_password.grafana["enabled"].result
  } : null
  sensitive = true
}

output "traefik_dashboard_url" {
  description = "Traefik dashboard URL (if enabled)"
  value       = var.enable_traefik && var.enable_traefik_dashboard ? "http://traefik.${var.base_domain}" : null
}

output "ingress_class" {
  description = "IngressClass name (Traefik)"
  value       = var.enable_traefik ? "traefik" : null
}

# Helpful commands
output "access_instructions" {
  description = "Helpful commands to interact with the cluster"
  value = {
    set_kubeconfig = "minikube -p ${var.cluster_name} kubeconfig get > ~/.kube/config"
    tunnel         = "minikube -p ${var.cluster_name} tunnel"
    dashboard      = "minikube -p ${var.cluster_name} dashboard"
    get_pods       = "kubectl get pods -A"
    get_ingress    = var.enable_traefik ? "kubectl get ingress -A" : null
  }
}
