# Providers configuration

provider "minikube" {
  # The provider incorrectly uses its own provider-level kubernetes_version
  # default during cluster creation instead of the resource attribute.
  kubernetes_version = var.kubernetes_version
}

provider "kubernetes" {
  host = minikube_cluster.this.host

  client_certificate     = minikube_cluster.this.client_certificate
  client_key             = minikube_cluster.this.client_key
  cluster_ca_certificate = minikube_cluster.this.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = minikube_cluster.this.host
    client_certificate     = minikube_cluster.this.client_certificate
    client_key             = minikube_cluster.this.client_key
    cluster_ca_certificate = minikube_cluster.this.cluster_ca_certificate
  }
}
