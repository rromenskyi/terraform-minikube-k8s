# Known bugs / follow-ups — terraform-minikube-k8s

Discovered during a full end-to-end bootstrap against the Docker driver on
Ubuntu 24.04 running a k3s cluster in parallel (shared host, shared kernel).

## 1. Kicbase's podman CNI bridge races with Flannel at initial boot

`gcr.io/k8s-minikube/kicbase` ships `/etc/cni/net.d/87-podman-bridge.conflist`
with its bridge `cni-podman0` configured for subnet **`10.244.0.0/16`** —
exactly the subnet Flannel claims on `cni0` (`10.244.0.1/24`).

The race: kubeadm's initial coredns install runs BEFORE Flannel's
DaemonSet drops `10-flannel.conflist`. During that window, the podman
conflist is the only CNI config available → kubelet uses it → `cni-podman0`
bridge is created with `10.244.0.1`. Then Flannel starts, brings up
`cni0` also at `10.244.0.1/24`. Two interfaces fight over the same IP.
ARP goes non-deterministic; a few minutes into the bootstrap, in-cluster
Service NAT degrades (`dial tcp 100.64.0.1:443: no route to host` from
coredns / metrics-server / kubernetes-dashboard).

The bug is in `kicbase` packaging (see upstream
[minikube#11194](https://github.com/kubernetes/minikube/issues/11194)
and [minikube#15797](https://github.com/kubernetes/minikube/issues/15797)),
which has been open since 2021. Minikube's own start process renames
the conflist to `*.mk_disabled`, but the *bridge* was already created by
the time that runs, so the interface persists and keeps its IP.

**Current consumer workaround** (in `terraform-minikube-platform/tf`
`bootstrap-minikube` subcommand, Step 1.5): after `minikube start` succeeds,
immediately `ip addr flush dev cni-podman0 && ip link set cni-podman0 down`.
This disarms the bridge without trying to delete it (deletion fails while
it still holds slave veths from the kubeadm coredns pod). Flannel's `cni0`
then wins the 10.244.0.1 address unopposed.

**Proposed fix inside this module:** add a `post_start` provisioner (or
a small resource chain) that performs the same disarm inside the minikube
container, so consumers don't have to script Step 1.5 themselves.
Alternative: publish a custom kicbase with the podman conflist removed,
and make it the module default.

## 2. Host prerequisites need module-side validation

Two host-level settings are load-bearing for a healthy bootstrap and have
nothing to do with Terraform:

- **`fs.inotify.max_user_instances`** — Ubuntu / Debian default is `128`,
  way too low for a Kubernetes node. kube-controller-manager, kube-proxy,
  coredns and every workload open their own inotify handles; the cluster
  "boots and then degrades" a few minutes in, with `too many open files`
  in the controller-manager log followed by cascading NAT / DNS failures.
  Raise to `8192` + `fs.inotify.max_user_watches=524288` in
  `/etc/sysctl.d/`.

- **Docker group membership** for the invoking user — `minikube start`
  connects to `/var/run/docker.sock` without elevation. Running Terraform
  via `sudo` is not an acceptable substitute (state file and provider
  caches end up root-owned).

Both are documented in README → "Host Prerequisites". A module-side
`check {}` block or preflight `null_resource` would surface the violation
before `minikube start` inherits a half-booted cluster:

```hcl
check "host_inotify_limits" {
  assert {
    condition = try(tonumber(
      local_file.inotify_instances.content
    ), 0) >= 1024
    error_message = "..."
  }
  ...
}
```

Alternative: emit a warning output, e.g.
`output "host_prereq_warnings" { value = [...] }`.
