# Known bugs / follow-ups — terraform-minikube-k8s

Discovered during a full end-to-end bootstrap against the Docker driver on
Ubuntu 24.04 running a k3s cluster in parallel (shared host, shared kernel).

## 1. Kicbase's bundled podman stack fights Flannel for `10.244.0.1`

`gcr.io/k8s-minikube/kicbase` bakes in the full podman runtime (see
[kubernetes/minikube `deploy/kicbase/Dockerfile`](https://github.com/kubernetes/minikube/blob/master/deploy/kicbase/Dockerfile)
— `clean-install podman catatonit crun` + `systemctl enable podman.socket`).
It is there for the `--driver=podman` code path and for operators who
`minikube ssh` in to run `podman` by hand. On `--driver=docker` stacks
it is unused — and actively harmful.

**The harm chain:** `podman.socket` is a systemd socket-activation unit
listening on `/run/podman/podman.sock`. Anything pinging that socket
(containerd CNI-reload loops, crictl probes, kubelet probing its known
runtime sockets) wakes `podman.service`. `podman.service` on first start
creates its default network `podman` — a bridge called `cni-podman0`
with `10.244.0.1/16`, the SAME address Flannel wants on `cni0`
(`10.244.0.1/24`). ARP goes non-deterministic, then a few minutes into
the bootstrap in-cluster Service NAT collapses: coredns, metrics-server,
kubernetes-dashboard loop on
`dial tcp 100.64.0.1:443: no route to host`.

We tried the half-measures first: disabling the `87-podman-bridge.conflist`
by renaming to `.disabled`, then `rm`-ing it, then `systemctl restart
containerd` to flush its CNI plugin cache (per upstream
[minikube#11194](https://github.com/kubernetes/minikube/issues/11194),
[minikube#8480](https://github.com/kubernetes/minikube/issues/8480),
[minikube#15797](https://github.com/kubernetes/minikube/issues/15797)).
Each one still let the bridge come back a few minutes later, on a fresh
Mac cluster identically to Linux.

**Current consumer workaround** (in `terraform-minikube-platform/tf`
`bootstrap-minikube` subcommand, Step 1.5): after `minikube start`
succeeds, nuke the podman stack inside the kicbase container — one
`docker exec` that disables `podman.socket`, removes `/usr/bin/podman`
and `/etc/containers/networks` + `/var/lib/containers/storage/networks`
+ `/var/lib/cni/networks/podman` + `/etc/cni/net.d/87-podman-bridge.conflist`,
then tears down the bridge if it already exists. No socket, no binary,
no network DB means there is nothing to regenerate it. Trade-off: inside
this specific kicbase node `minikube ssh -- podman run …` and
`--driver=podman` no longer work; on a `--driver=docker` stack neither
is used.

**Proposed fix inside this module:** run the same podman purge as a
post-`minikube_cluster.this` `null_resource` provisioner so consumers
don't have to script Step 1.5 themselves. Alternative: publish a
custom kicbase without the podman package, make it the module default
via `var.base_image`.

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
