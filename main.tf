# Minikube Cluster
resource "minikube_cluster" "this" {
  vm                = true
  driver            = var.driver
  cluster_name      = var.cluster_name
  nodes             = var.nodes
  cpus              = var.cpus
  memory            = var.memory
  cni               = var.cni
  network           = "builtin"
  container_runtime = "docker"
  base_image        = var.base_image
  iso_url           = var.iso_urls

  # Addons (Traefik and cert-manager are installed via Helm instead of minikube addons)
  addons = var.addons

  # Networking configuration using 100.64.0.0/10 CGNAT range to avoid conflicts
  # service_cidr passed via extra_config for kubeadm
  extra_config = toset([
    "kubeadm.service-cluster-ip-range=${var.service_cidr}",
    "kubeadm.cluster-dns=${var.dns_ip}",
    "kubelet.cluster-dns=${var.dns_ip}",
  ])

  lifecycle {
    ignore_changes = [
      iso_url,
    ]
  }
}

# Optional ops workload (StatefulSet with persistent volume)
resource "kubernetes_stateful_set_v1" "ops" {
  count = var.create_ops_workload ? 1 : 0

  metadata {
    name      = "ops"
    namespace = var.namespace
    labels    = { app = "ops" }
  }

  spec {
    service_name = "ops"
    replicas     = 1

    selector {
      match_labels = { app = "ops" }
    }

    template {
      metadata {
        labels = { app = "ops" }
      }

      spec {
        container {
          name    = "ops"
          image   = var.ops_image
          command = ["sh", "-c", "tail -f /dev/null"]

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        termination_grace_period_seconds = 10
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

# Create additional namespaces
resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.key
  }
}

# IngressClass is now managed in traefik.tf
