# terraform-minikube-k8s

**A full-featured local Kubernetes platform module powered by Terraform and Minikube.**

This module is designed for a Terraform-first workflow: the normal bootstrap path is Terraform itself creating the Minikube cluster and then converging platform services on top of it.

## Operating Model

- Use Terraform as the entrypoint for cluster lifecycle and platform rollout.
- Do not rely on a manual `minikube start` before `terraform apply` for normal bootstrap.
- If bootstrap is broken, fix Terraform/module logic instead of adding manual runbook steps.
- Keep Terraform backend configuration in the consuming root stack or example, not in this reusable module source.
- Traefik, cert-manager, monitoring, namespaces, and demo workloads are intended to converge from Terraform in one flow.

Includes a modern stack for local development and experimentation:

- **Traefik** — Ingress Controller with built-in Dashboard
- **cert-manager** + Let's Encrypt (staging + production issuers)
- **Prometheus + Grafana** — complete observability stack
- Automatic namespace provisioning
- Demo application with TLS termination

---

## Quick Start

1. Deploy the full demo:

```bash
cd examples/demo
terraform init
terraform apply
```

`terraform apply` is expected to bootstrap Minikube itself and then converge the platform services in the same run.

After deployment, run in a separate terminal if you need a local LoadBalancer tunnel:
```bash
minikube -p demo-cluster tunnel
```

**Get Grafana password:**
```bash
terraform output -json grafana_credentials | jq -r '.value.password'
```

---

## What's Included

- `cluster.tf` — Minikube cluster + networking (uses 100.64.0.0/10 CGNAT range)
- `_providers.tf` — All provider configurations
- `traefik.tf` — Traefik Ingress + Dashboard IngressRoute
- `cert_manager.tf` — cert-manager + Let's Encrypt ClusterIssuers
- `monitoring.tf` — kube-prometheus-stack (Prometheus + Grafana)

## Examples

- [`examples/basic/`](examples/basic/) — Minimal configuration
- [`examples/demo/`](examples/demo/) — Full platform with demo app, TLS, and monitoring (**recommended**)

## Development

### Pre-commit hooks (recommended)

This project uses [pre-commit](https://pre-commit.com/) to ensure code quality:

```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# Run manually
pre-commit run -a
```

### Useful Commands

```bash
# View all outputs
terraform output

# Get Grafana password
terraform output -json grafana_credentials | jq -r '.value.password'

# Open dashboards
minikube -p demo-cluster dashboard
```

**Note:** The CI pipeline will also run `terraform fmt`, `validate`, and `terraform-docs`.

## AI Assistant Configuration

This repository includes `AGENT.md` and a `skills/` directory with structured engineering guidelines.

These files encode Terraform, Kubernetes, SRE, and code quality best practices. When used with an AI coding assistant that has repository context, they reinforce repository standards, architecture principles, and English-only repository content.
To extend the guidelines, add new focused files to the `skills/` directory.

---

**Built for Terraform-first local Kubernetes platform bootstrap.**

Feel free to fork, improve, and use in your projects. Pull requests are welcome.

---

**License:** MIT
**Author:** @rromenskyi

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_minikube"></a> [minikube](#requirement\_minikube) | ~> 0.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_minikube"></a> [minikube](#provider\_minikube) | 0.6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_issuers](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.monitoring](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.traefik](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_class_v1.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_class_v1) | resource |
| [kubernetes_ingress_v1.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace_v1.namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_stateful_set_v1.ops](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/stateful_set_v1) | resource |
| [minikube_cluster.this](https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster) | resource |
| [random_password.grafana](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_addons"></a> [addons](#input\_addons) | List of minikube addons to enable | `list(string)` | ```[ "dashboard", "default-storageclass", "ingress", "storage-provisioner", "metrics-server" ]``` | no |
| <a name="input_base_image"></a> [base\_image](#input\_base\_image) | Base image for minikube | `string` | `"gcr.io/k8s-minikube/kicbase:v0.0.48"` | no |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | cert-manager Helm chart version | `string` | `"v1.16.1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the minikube cluster | `string` | `"tf-local"` | no |
| <a name="input_cni"></a> [cni](#input\_cni) | CNI to use (bridge, calico, cilium, flannel, etc). Calico recommended for better ingress support. | `string` | `"calico"` | no |
| <a name="input_cpus"></a> [cpus](#input\_cpus) | Number of CPUs | `number` | `4` | no |
| <a name="input_create_ops_workload"></a> [create\_ops\_workload](#input\_create\_ops\_workload) | Whether to create the ops StatefulSet workload | `bool` | `true` | no |
| <a name="input_dns_ip"></a> [dns\_ip](#input\_dns\_ip) | IP address for CoreDNS/kube-dns (must be inside service\_cidr) | `string` | `"100.64.0.10"` | no |
| <a name="input_driver"></a> [driver](#input\_driver) | Minikube driver (docker, qemu, hyperkit, etc) | `string` | `"docker"` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Deploy cert-manager + Let's Encrypt ClusterIssuers | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Deploy Prometheus + Grafana via kube-prometheus-stack | `bool` | `true` | no |
| <a name="input_enable_traefik"></a> [enable\_traefik](#input\_enable\_traefik) | Deploy Traefik as Ingress controller via Helm | `bool` | `true` | no |
| <a name="input_enable_traefik_dashboard"></a> [enable\_traefik\_dashboard](#input\_enable\_traefik\_dashboard) | Expose Traefik dashboard via IngressRoute | `bool` | `true` | no |
| <a name="input_iso_urls"></a> [iso\_urls](#input\_iso\_urls) | List of ISO URLs to try | `list(string)` | ```[ "https://storage.googleapis.com/minikube/iso/minikube-v1.37.0-amd64.iso", "https://github.com/kubernetes/minikube/releases/download/v1.37.0/minikube-v1.37.0-amd64.iso" ]``` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the Minikube cluster (for example `v1.30.0` or `stable`) | `string` | `"stable"` | no |
| <a name="input_letsencrypt_email"></a> [letsencrypt\_email](#input\_letsencrypt\_email) | Email for Let's Encrypt registration (required for cert-manager) | `string` | `"admin@example.com"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in MB | `number` | `4096` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for workloads | `string` | `"default"` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | List of additional namespaces to create | `list(string)` | ```[ "ops", "monitoring" ]``` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Number of nodes | `number` | `1` | no |
| <a name="input_ops_image"></a> [ops\_image](#input\_ops\_image) | Image to use for the ops workload | `string` | `"alpine:3.20"` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | CIDR range for Pods (if supported by CNI) | `string` | `"100.72.0.0/13"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR range for Kubernetes Services (ClusterIP) | `string` | `"100.64.0.0/13"` | no |
| <a name="input_traefik_version"></a> [traefik\_version](#input\_traefik\_version) | Traefik Helm chart version | `string` | `"34.2.0"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_instructions"></a> [access\_instructions](#output\_access\_instructions) | Helpful commands to interact with the cluster |
| <a name="output_addons"></a> [addons](#output\_addons) | Enabled minikube addons |
| <a name="output_cert_manager_enabled"></a> [cert\_manager\_enabled](#output\_cert\_manager\_enabled) | Whether cert-manager is enabled |
| <a name="output_client_certificate"></a> [client\_certificate](#output\_client\_certificate) | Client certificate for authentication |
| <a name="output_client_key"></a> [client\_key](#output\_client\_key) | Client key for authentication |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | Cluster CA certificate |
| <a name="output_cluster_host"></a> [cluster\_host](#output\_cluster\_host) | Kubernetes API server host |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created minikube cluster |
| <a name="output_dns_ip"></a> [dns\_ip](#output\_dns\_ip) | CoreDNS IP address |
| <a name="output_grafana_credentials"></a> [grafana\_credentials](#output\_grafana\_credentials) | Grafana login credentials (password is randomly generated and stored in Terraform state) |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | Grafana URL |
| <a name="output_ingress_class"></a> [ingress\_class](#output\_ingress\_class) | IngressClass name (Traefik) |
| <a name="output_kubeconfig_command"></a> [kubeconfig\_command](#output\_kubeconfig\_command) | Command to get kubeconfig for this cluster |
| <a name="output_kubeconfig_path"></a> [kubeconfig\_path](#output\_kubeconfig\_path) | Typical path to the kubeconfig file |
| <a name="output_monitoring_enabled"></a> [monitoring\_enabled](#output\_monitoring\_enabled) | Whether Prometheus + Grafana stack is enabled |
| <a name="output_namespaces"></a> [namespaces](#output\_namespaces) | Created namespaces |
| <a name="output_ops_statefulset_name"></a> [ops\_statefulset\_name](#output\_ops\_statefulset\_name) | Name of the ops StatefulSet (if created) |
| <a name="output_pod_cidr"></a> [pod\_cidr](#output\_pod\_cidr) | Configured Pod CIDR |
| <a name="output_service_cidr"></a> [service\_cidr](#output\_service\_cidr) | Configured Service CIDR |
| <a name="output_traefik_enabled"></a> [traefik\_enabled](#output\_traefik\_enabled) | Whether Traefik is enabled |
<!-- END_TF_DOCS -->
