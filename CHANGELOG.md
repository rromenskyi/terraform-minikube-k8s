# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for configurable backend via environment variables (`.env`)
- Improved bootstrap documentation for Backblaze B2

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
