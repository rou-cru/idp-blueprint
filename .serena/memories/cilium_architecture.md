# Cilium — CNI/Gateway/Observability (validated 2025-12-27)

## Configuration (repo)
- Chart values: `IT/cilium/values.yaml`.
- CNI exclusive (`cni.exclusive: true`, chaining `none`).
- kube-proxy replacement enabled.
- L7 proxy + Envoy enabled (required for Gateway API).
- Gateway API enabled; Ingress controller disabled.
- Hubble enabled with relay + UI + metrics.
- L2 announcements and BGP disabled (k3d demo); encryption disabled.
- BPF host routing + masquerade disabled for k3d compatibility.

## Runtime state (cluster)
- DaemonSets: `cilium`, `cilium-envoy` (ready).
- Deployments: `cilium-operator`, `hubble-relay`, `hubble-ui` (ready).
- Services: `cilium-agent` (9962), `cilium-envoy` (9964), `cilium-operator` (9963), `hubble-metrics` (9091), `hubble-relay`, `hubble-ui` (80).
- ConfigMap `cilium-config` confirms:
  - `kube-proxy-replacement: true`
  - `enable-gateway-api: true`
  - `enable-l7-proxy: true`
  - Hubble enabled with metrics set `dns:query;ignoreAAAA drop tcp flow port-distribution icmp http`.

## Observability (cluster)
- ServiceMonitors exist for `cilium-agent`, `cilium-envoy`, `cilium-operator`, and `hubble` (namespace `kube-system`).
- Prometheus ServiceMonitor selector is empty (`{}`), so these are eligible for scraping.
- No HTTPRoute published for Hubble UI (ClusterIP only).