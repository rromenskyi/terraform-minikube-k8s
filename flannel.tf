# Flannel install, Terraform-native.
#
# Historically this module asked the minikube provider to deploy Flannel
# via its built-in `flannel` CNI addon. That code path pre-renders the
# `kube-flannel-cfg` ConfigMap with `"Network": "10.244.0.0/16"` hardcoded,
# IGNORES `kubeadm.pod-network-cidr` entirely, and leaves the operator
# stuck on 10.244 — which collides with kicbase's bundled `cni-podman0`
# bridge (same 10.244.0.1 gateway). ARP goes non-deterministic and
# in-cluster Service NAT collapses a few minutes into bootstrap.
#
# This file disables the minikube addon and owns Flannel ourselves:
# fetch the upstream manifest, replace 10.244.0.0/16 with `var.pod_cidr`,
# apply every document through the `kubectl` provider. The `net-conf.json`
# inside `kube-flannel-cfg` is therefore rendered from Terraform and
# matches whatever `var.pod_cidr` is set to — no hardcoded subnet, no
# ConfigMap-patching null_resource, no kubectl shell-out.

data "http" "flannel_manifest" {
  url = "https://github.com/flannel-io/flannel/releases/download/${var.flannel_version}/kube-flannel.yml"

  request_headers = {
    Accept = "text/plain, application/yaml, */*"
  }
}

locals {
  # One occurrence of 10.244.0.0/16 in the upstream manifest: inside the
  # `kube-flannel-cfg` ConfigMap's `net-conf.json` key. Replace it with
  # our configured pod CIDR; Flannel reads that value at pod startup and
  # uses it as the network-wide /16 from which per-node /24 slices are
  # carved out.
  flannel_rendered = replace(
    data.http.flannel_manifest.response_body,
    "10.244.0.0/16",
    var.pod_cidr,
  )

  # Split the multi-document YAML, drop empty chunks, decode each once to
  # extract `kind` + `metadata.name`, key the map by `<Kind>/<Name>` so
  # state addresses read like
  #   module.k8s.kubectl_manifest.flannel["DaemonSet/kube-flannel-ds"]
  # instead of the anonymous "0".."5" indices.
  flannel_all_docs = {
    for parsed in [
      for doc in split("---\n", local.flannel_rendered) :
      {
        yaml    = doc
        decoded = yamldecode(doc)
      }
      if length(trimspace(doc)) > 0
    ] :
    "${parsed.decoded.kind}/${parsed.decoded.metadata.name}" => parsed.yaml
  }

  # Split into (a) Namespace, which must exist before anything else, and
  # (b) everything else — ConfigMap, ClusterRole, ClusterRoleBinding,
  # ServiceAccount, DaemonSet — which `depends_on` the Namespace.
  # `kubectl_manifest` resources with `for_each` run in parallel by
  # default; without the split, the DaemonSet and ConfigMap race the
  # Namespace and fail with "namespaces kube-flannel not found".
  flannel_namespace_docs = {
    for k, v in local.flannel_all_docs : k => v if startswith(k, "Namespace/")
  }
  flannel_other_docs = {
    for k, v in local.flannel_all_docs : k => v if !startswith(k, "Namespace/")
  }
}

resource "kubectl_manifest" "flannel_namespace" {
  for_each  = local.flannel_namespace_docs
  yaml_body = each.value

  depends_on = [minikube_cluster.this]
}

resource "kubectl_manifest" "flannel" {
  for_each  = local.flannel_other_docs
  yaml_body = each.value

  # Wait for Deployment/DaemonSet rollout (no-op for ConfigMap / ClusterRole
  # / ClusterRoleBinding / ServiceAccount, which the provider treats as
  # synchronously-created). On the Flannel DaemonSet this blocks until
  # every node reports the pod Ready — which means
  # /etc/cni/net.d/10-flannel.conflist is dropped and /run/flannel/subnet.env
  # is written on each node, so the next kubelet pod sandbox creation
  # succeeds instead of looping on "cni plugin not initialized".
  wait_for_rollout = true

  depends_on = [kubectl_manifest.flannel_namespace]
}
