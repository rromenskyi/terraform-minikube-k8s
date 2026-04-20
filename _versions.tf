terraform {
  required_version = ">= 1.5.0"

  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "~> 0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    # Applies our own Flannel manifest against the fresh cluster with
    # `var.pod_cidr` rendered into its ConfigMap. `gavinbunney/kubectl` is
    # chosen over `hashicorp/kubernetes.kubernetes_manifest` because the
    # latter requires the API server to be reachable at *plan* time (it
    # fetches OpenAPI schemas), which is a chicken-and-egg problem on a
    # fresh bootstrap; `kubectl_manifest` is lazy and only talks to the
    # cluster at apply time.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }

    # Fetches the upstream Flannel manifest once per plan so we stay
    # mechanically close to what flannel-io publishes and can version-pin
    # with `var.flannel_version`.
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}
