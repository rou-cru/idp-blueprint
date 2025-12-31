# cert-manager — Issuers, Certs, Metrics (validated 2025-12-27)

## Deployment (cluster)
- Namespace `cert-manager` has deployments:
  - `cert-manager`, `cert-manager-cainjector`, `cert-manager-webhook` (all ready).

## Issuers & certificates (cluster)
- ClusterIssuers:
  - `self-signed-issuer` (Ready=True)
  - `ca-issuer` (Ready=True)
- Certificate:
  - `idp-wildcard-cert` in `kube-system` (Ready=True), used by Gateway TLS.

## Configuration (repo)
- Chart values: `IT/cert-manager/values.yaml`.
- CRDs enabled.
- Prometheus ServiceMonitor enabled.
- Controller logging in JSON.
- Pod placement: control-plane affinity + toleration.

## Observability (cluster)
- ServiceMonitor `cert-manager` exists (cluster-wide).