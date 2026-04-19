locals {
  # Path where this module writes the composed kubeconfig. The consumer
  # (typically `terraform-k8s-addons`) references it via `config_path` in
  # its `kubernetes` / `helm` providers.
  kubeconfig_path = "${path.root}/.terraform/minikube-${var.cluster_name}.kubeconfig"

  # Kubeconfig content is assembled from the minikube provider's attributes
  # and written to disk as a single-context YAML so tools downstream can
  # treat this cluster like any other kubeconfig target.
  kubeconfig_yaml = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = var.cluster_name
    clusters = [{
      name = var.cluster_name
      cluster = {
        server                     = minikube_cluster.this.host
        certificate-authority-data = base64encode(minikube_cluster.this.cluster_ca_certificate)
      }
    }]
    users = [{
      name = var.cluster_name
      user = {
        client-certificate-data = base64encode(minikube_cluster.this.client_certificate)
        client-key-data         = base64encode(minikube_cluster.this.client_key)
      }
    }]
    contexts = [{
      name = var.cluster_name
      context = {
        cluster = var.cluster_name
        user    = var.cluster_name
      }
    }]
  })
}
