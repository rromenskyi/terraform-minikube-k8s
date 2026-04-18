# terraform-minikube-k8s Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `base_domain` variable (default: `"localhost"`). Traefik dashboard and Grafana hostnames are now derived as `traefik.<base_domain>` and `grafana.<base_domain>` instead of hardcoded `*.localhost`. Also surfaces a new `traefik_dashboard_url` output.

### Fixed
- kube-prometheus-stack no longer creates its own Grafana Ingress. The chart-side `grafana.ingress.*` settings were stripped from the Helm release, so the only Ingress targeting `grafana.localhost` is now the Terraform-managed `kubernetes_ingress_v1.grafana` (which carries the required Traefik router annotations). Removes a duplicate Ingress with conflicting ownership on the same host.

### Added
- `ops_storage_class_name` variable pins the StorageClass used by the ops StatefulSet's PVC (default: `"standard"`, matching minikube's `default-storageclass` addon). Removes the silent `Pending` PVC that would hang the workload if the default-storageclass addon were disabled.
- `apiserver_cert_extra_sans` variable surfaces the apiserver cert SAN list. The default keeps `192.168.49.2` (minikube's docker-driver node IP) for backwards compatibility; users on qemu / hyperkit / kvm2 / vmware can now override with their driver-specific node IP instead of hitting a TLS handshake failure
- Pod Security Standards labels (`enforce`/`audit`/`warn`) applied to every module-managed namespace via the new `namespace_pod_security_level` variable (default: `baseline`)
- Default `kubernetes_resource_quota_v1` (4/8 CPU requests/limits, 8Gi/16Gi memory, 50 pods) and `kubernetes_limit_range_v1` (100m/128Mi request, 500m/512Mi limit per container) applied to each module-managed namespace. Gated by the new `enable_namespace_limits` variable (default: `true`)
- `ops` StatefulSet now runs with a hardened `security_context`: `runAsNonRoot`, UID/GID 1000, `readOnlyRootFilesystem`, all Linux capabilities dropped, `RuntimeDefault` seccomp profile, and bounded `resources.requests`/`limits` — i.e., compatible with `restricted` PodSecurity

### Changed
- `minikube_cluster.this` now ignores drift on force-new attributes (`addons`, `base_image`, `kubernetes_version`, `extra_config`, `cni`, `driver`, `nodes`, `cpus`, `memory` in addition to the existing `iso_url`) to stop silent destroy+recreate on unrelated variable edits. To reshape any of these, run `terraform taint minikube_cluster.this` + `terraform apply`, or destroy and reapply.

## [2.0.0] - 2026-04-14

### Breaking
- Renamed the public module repository/source to `terraform-minikube-k8s`
- Removed backend configuration and backend-related inputs from the reusable module source; backend configuration now belongs only in consumer root stacks

### Added
- Added explicit `kubernetes_version` support for pinning the Kubernetes version inside the Minikube cluster

### Changed
- Made bootstrap safer for clean machines by moving cert-manager ClusterIssuers to a local Helm chart instead of `kubernetes_manifest`
- Kept Traefik dashboard configuration inside the Traefik Helm release instead of splitting it into a separate Terraform-managed manifest
- Removed the redundant empty `provider "minikube"` block
- Removed root-only backend and wrapper assumptions from the reusable module
- Renamed repository references from `terraform-minikube-platform`/`terraform-minikube-aks` to `terraform-minikube-k8s`
- Standardized repository-facing content on English-only documentation and guidance

### Documentation
- Clarified that the module is intended for Terraform-first bootstrap rather than manual Minikube startup

## [1.3.0] - 2025-04-14

### Added
- `AGENT.md` and `skills/` directory with structured engineering guidelines for AI assistants
- Public documentation of AI Assistant Configuration in README

### Changed
- Updated README.md to refer to "AI Assistant Configuration" instead of internal tool names
- Made developer experience files part of the public module

### Documentation
- Improved section about how the repository helps AI coding tools maintain high quality standards

## [1.2.0] - 2025-04-14

### Changed
- **Major architecture refactor**: Split `main.tf` into focused files (`cluster.tf`, `namespaces.tf`, `workloads.tf`, `locals.tf`)
- Replaced all `count = var.enabled ? 1 : 0` with modern `for_each = var.enabled ? toset(["enabled"]) : toset([])` pattern
- Removed all explicit `depends_on` blocks (Terraform implicit dependencies are sufficient and cleaner)
- Added comprehensive `validation` blocks for critical variables (cluster name, CIDRs, email)
- Introduced `local.common_labels` applied consistently across all resources
- Updated `kube-prometheus-stack` to v70.0.0
- Significantly improved code quality, comments, and adherence to Terraform best practices

### Added
- `locals.tf` with standardized labeling
- Strong input validation (Terraform God Mode)
- Consistent labeling following Kubernetes and Terraform conventions
- Updated repository engineering guidance (`AGENT.md` + `skills/` directory)

### Removed
- Redundant `depends_on` declarations
- Old `count`-based conditional resources
- Duplicated logic between files

### Improved
- Code is now much more maintainable, idiomatic, and production-grade
- Better separation of concerns
- Enhanced documentation and inline comments
- Stronger alignment with Staff+ engineering standards

### Documentation
- Updated `README.md` with the engineering guidelines section
- All skill files (`AGENT.md`, `skills/*.md`) rewritten in professional English
- Improved module structure documentation

**This release brings the module to a true "Terraform God Mode" quality level.**

## [1.0.0] - 2025-04-14

### Added
- Full local Kubernetes development platform using Minikube
- **Traefik** as Ingress Controller with built-in Dashboard (via Helm + IngressRoute)
- **cert-manager** with Let's Encrypt ClusterIssuers (staging + production)
- **Prometheus + Grafana** via `kube-prometheus-stack`
- Automatic namespace creation (`ops`, `monitoring`, etc.)
- Demo application with Ingress, TLS (cert-manager), and LoadBalancer service
- Random password generation for Grafana (stored in Terraform state)
- Configurable CNI (`calico` recommended), networking (100.64.0.0/10 CGNAT range)
- Remote state support for Backblaze B2 (S3 compatible)
- Comprehensive documentation and examples
- Bootstrap wrapper script (`tf`) that loads `.env`
- Full English documentation, LICENSE, and CONTRIBUTING guide

### Security
- No hardcoded credentials in the repository
- Grafana admin password is randomly generated on first apply
- Sensitive values are marked as `sensitive = true` in outputs
- `.env` is properly gitignored (`.env.example` is committed)

### Documentation
- Clear Quick Start guide with Backblaze B2 setup instructions
- Examples for both minimal and full-featured deployments
- Instructions on how to retrieve Grafana credentials
- Architecture overview

---

**Initial public release.**

This module evolved from a simple Minikube Terraform configuration into a complete local Kubernetes platform.
