# minikube-platform

**A full-featured local Kubernetes development platform powered by Terraform and Minikube.**

Includes a modern stack perfect for local development and experimentation:

- **Traefik** — Ingress Controller with built-in Dashboard
- **cert-manager** + Let's Encrypt (staging + production issuers)
- **Prometheus + Grafana** — complete observability stack
- Automatic namespace provisioning
- Demo application with TLS termination
- Remote state stored in Backblaze B2 (S3-compatible)

---

## Quick Start

1. Sign up at **[Backblaze B2](https://www.backblaze.com/b2/)** (free tier available)
2. Create a Bucket (e.g. `tfstate-unique`)
3. Generate an **Application Key** with access to that bucket
4. Copy and configure environment:

```bash
cp .env.example .env
# Edit .env with your credentials
```

5. Deploy the full demo:

```bash
cd examples/demo
cp ../../.env.example .env
../../tf init
../../tf apply
```

After deployment, run in a separate terminal:
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
- `providers.tf` — All provider configurations
- `traefik.tf` — Traefik Ingress + Dashboard IngressRoute
- `cert_manager.tf` — cert-manager + Let's Encrypt ClusterIssuers
- `monitoring.tf` — kube-prometheus-stack (Prometheus + Grafana)
- `backend.tf` — Remote state in Backblaze B2

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

## Backend Setup (Backblaze B2)

This module uses an S3-compatible backend for storing Terraform state.
**Backblaze B2** is recommended — it's cheap, reliable, and easy to set up.

See `.env.example` for configuration details.

---

**Built for comfortable local Kubernetes development.**

Feel free to fork, improve, and use in your projects. Pull requests are welcome.

---

**License:** MIT
**Author:** @rromenskyi

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.
