# Providers configuration

provider "minikube" {}

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
