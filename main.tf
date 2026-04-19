# Root module entrypoint — cluster bootstrap only.
#
# This module owns the distribution-specific concerns of provisioning a
# local minikube cluster: the `scott-the-programmer/minikube` provider
# runs `minikube start` synchronously, the module composes a kubeconfig
# file from the resulting host + certificate attributes, and exposes it at
# `kubeconfig_path`. The opinionated platform layer (Traefik / cert-manager /
# monitoring / namespaces / demo ops StatefulSet) lives in the sibling
# `terraform-k8s-addons` module and is consumed on top of this one —
# see the module README for composition examples.
#
# Resources are split across files:
# - cluster.tf  — minikube_cluster + composed kubeconfig local_file
# - locals.tf   — derived paths and labels
