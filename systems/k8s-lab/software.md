# k8s-lab — Software

Ubuntu Server 24.04 LTS (cloud image) running single-node [k3s](https://k3s.io/),
installed from the official `get.k3s.io` script in cloud-init.

## k3s configuration

Installed with `INSTALL_K3S_EXEC="--disable=traefik --write-kubeconfig-mode=0644"`:

| Choice                       | Rationale                                                                                       |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| `--disable=traefik`          | k3s bundles Traefik as default ingress; we use Envoy Gateway instead. Disabled to avoid conflict. |
| servicelb (klipper) **kept** | Envoy Gateway creates a `Service` of type `LoadBalancer` for the Gateway; on single-node k3s, servicelb binds it to the node IP — exactly what we want for `mcp.lab.yourdomain.com`. |
| Flannel CNI (default)        | Default k3s CNI; sufficient for single-node. No reason to swap.                                 |
| `--write-kubeconfig-mode=0644` | Lets the `admin` user run `kubectl`/`helm` without sudo. Lab convenience; acceptable on a single-tenant box. |

kubeconfig lives at `/etc/rancher/k3s/k3s.yaml`. Copy it to a workstation (rewrite the
`server:` host from `127.0.0.1` to the VM IP) for remote `kubectl`/`helm` from the deploy
script.

Installed k3s **v1.35.5+k3s1** (Kubernetes v1.35.5), pulled from the `stable` channel by
the `get.k3s.io` script on first boot (2026-06-03). Local `kubectl` is v1.34.1 — one minor
behind the server, within the supported ±1 skew.

## Stack installed on top (see envoy-ai-gateway)

Gateway API CRDs, Envoy Gateway, Envoy AI Gateway v0.5, and cert-manager are installed by
the [envoy-ai-gateway](../envoy-ai-gateway/) workload, not baked into this image — keeping
the VM image generic and the gateway stack as versioned IaC in that system's `config/`.
