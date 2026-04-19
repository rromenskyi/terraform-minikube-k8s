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

`terraform apply` bootstraps Minikube itself in a single phase. To layer
Traefik, cert-manager, kube-prometheus-stack and the demo workload on
top, compose this module with [`terraform-k8s-addons`](https://github.com/rromenskyi/terraform-k8s-addons)
in the same root (see the `examples/demo/` stack below).

After deployment, run in a separate terminal if you need a local LoadBalancer tunnel:
```bash
minikube -p demo-cluster tunnel
```

---

## What's Included

- `cluster.tf` — Minikube cluster + networking (uses 100.64.0.0/10 CGNAT range)
- `_providers.tf` — minikube + local provider config (only what bootstrap needs)

Anything platform-level (Traefik, cert-manager, kube-prometheus-stack,
PodSecurity-labeled namespaces, demo ops StatefulSet) moved to the sibling
`terraform-k8s-addons` module — consume it on top via
`module "addons" { kubeconfig_path = module.k8s.kubeconfig_path ... }`.
This module's only job is standing a Minikube cluster up and producing a
kubeconfig — see the output signature at the bottom of this README.

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

# Export kubeconfig for kubectl / helm
eval "$(terraform output -raw kubeconfig_command)"

# Built-in minikube dashboard (addons = ["dashboard"] by default)
minikube -p demo-cluster dashboard
```

Grafana, the Traefik dashboard and similar platform UIs live on
`terraform-k8s-addons` (and the stack it plugs into) — consult that
module's README + `grafana_credentials` output once it's composed on top.

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
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_minikube"></a> [minikube](#requirement\_minikube) | ~> 0.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_local"></a> [local](#provider\_local) | 2.8.0 |
| <a name="provider_minikube"></a> [minikube](#provider\_minikube) | 0.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [minikube_cluster.this](https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_addons"></a> [addons](#input\_addons) | List of minikube addons to enable. Ingress-related addons are intentionally absent — Traefik is installed via the sibling `terraform-k8s-addons` module. | `list(string)` | ```[ "dashboard", "default-storageclass", "storage-provisioner", "metrics-server" ]``` | no |
| <a name="input_apiserver_cert_extra_sans"></a> [apiserver\_cert\_extra\_sans](#input\_apiserver\_cert\_extra\_sans) | Additional Subject Alternative Names embedded in the apiserver certificate. The default covers minikube's docker driver node IP (`192.168.49.2`). When using qemu / hyperkit / kvm2 / vmware, run `minikube ip -p <cluster>` after bootstrap and extend this list with the driver-specific node IP. | `list(string)` | ```[ "localhost", "127.0.0.1", "10.0.0.1", "192.168.49.2" ]``` | no |
| <a name="input_base_image"></a> [base\_image](#input\_base\_image) | Base image for minikube | `string` | `"gcr.io/k8s-minikube/kicbase:v0.0.50"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the minikube cluster | `string` | `"tf-local"` | no |
| <a name="input_cni"></a> [cni](#input\_cni) | CNI to use (bridge, calico, cilium, flannel, etc). Flannel is recommended on the macOS Docker driver. | `string` | `"calico"` | no |
| <a name="input_cpus"></a> [cpus](#input\_cpus) | Number of CPUs | `number` | `6` | no |
| <a name="input_dns_ip"></a> [dns\_ip](#input\_dns\_ip) | IP address for CoreDNS/kube-dns (must be inside service\_cidr) | `string` | `"100.64.0.10"` | no |
| <a name="input_driver"></a> [driver](#input\_driver) | Minikube driver (docker, qemu, hyperkit, etc) | `string` | `"docker"` | no |
| <a name="input_iso_urls"></a> [iso\_urls](#input\_iso\_urls) | List of ISO URLs to try | `list(string)` | ```[ "https://storage.googleapis.com/minikube/iso/minikube-v1.37.0-amd64.iso", "https://github.com/kubernetes/minikube/releases/download/v1.37.0/minikube-v1.37.0-amd64.iso" ]``` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the Minikube cluster (for example `v1.30.0` or `stable`) | `string` | `"stable"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in MB | `number` | `6144` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Number of nodes | `number` | `1` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | CIDR range for Pods (if supported by CNI) | `string` | `"10.244.0.0/16"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR range for Kubernetes Services (ClusterIP) | `string` | `"100.64.0.0/13"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_instructions"></a> [access\_instructions](#output\_access\_instructions) | Helpful commands to interact with the cluster |
| <a name="output_addons"></a> [addons](#output\_addons) | Enabled minikube addons |
| <a name="output_client_certificate"></a> [client\_certificate](#output\_client\_certificate) | Client certificate (PEM) for authentication |
| <a name="output_client_key"></a> [client\_key](#output\_client\_key) | Client key (PEM) for authentication |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | Cluster CA certificate (PEM) |
| <a name="output_cluster_distribution"></a> [cluster\_distribution](#output\_cluster\_distribution) | Which Kubernetes distribution this module provisions. Lets consumer modules (e.g. `terraform-k8s-addons`) branch on distribution programmatically instead of hardcoding a source path. |
| <a name="output_cluster_host"></a> [cluster\_host](#output\_cluster\_host) | Kubernetes API server host |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created minikube cluster |
| <a name="output_dns_ip"></a> [dns\_ip](#output\_dns\_ip) | CoreDNS IP address |
| <a name="output_kubeconfig_command"></a> [kubeconfig\_command](#output\_kubeconfig\_command) | Shell command to export this cluster's kubeconfig for kubectl/helm |
| <a name="output_kubeconfig_path"></a> [kubeconfig\_path](#output\_kubeconfig\_path) | Local path to the composed kubeconfig file for this cluster. Wire this into `module "addons" { kubeconfig_path = module.k8s.kubeconfig_path }` in the platform root. The value references `local_sensitive_file.kubeconfig.filename` (not the `local.kubeconfig_path` literal) so the Terraform dependency graph makes downstream consumers wait for the file to land on disk before they try to open it. |
| <a name="output_pod_cidr"></a> [pod\_cidr](#output\_pod\_cidr) | Configured Pod CIDR |
| <a name="output_service_cidr"></a> [service\_cidr](#output\_service\_cidr) | Configured Service CIDR |
<!-- END_TF_DOCS -->
