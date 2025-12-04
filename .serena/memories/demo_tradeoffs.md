# Demo-Mode Tradeoffs (validated 2025-12-04)

Conscious choices made to keep the demo deployable on laptop-class hardware; these are not production-ready:

- **Config credentials in Git**: `config.toml` ships with known credentials (github_token, docker registry user/pass, ArgoCD/Grafana/SonarQube/Backstage Dex defaults). They seed Vault for quick starts; must be blank/rotated for real use.
- **Vault relaxed posture**: Standalone, TLS disabled (`tls_disable="true"`), unseal/root token stored in K8s Secret, key-shares=1/threshold=1. Chosen for zero external dependencies in demos.
- **Gateway via NodePort + nip.io**: Uses k3d host port mapping (30080/30443) and nip.io wildcard; LoadBalancer/L2 announcements disabled. Suitable for k3d but not prod.
- **envsubst client-side**: Dynamic values (DNS_SUFFIX, NodePorts, repo/branch) rendered locally before apply, so manifests aren’t pure GitOps and rendered values aren’t tracked. Kept for portability across arbitrary LAN IPs in demos.
- **Backstage simplified**: DNS_SUFFIX/grafana/dex URLs rendered via job and placeholders; uses demo secrets; no corporate SSO/RBAC hardening.
- **Observability short retention**: Loki filesystem backend with 6h retention and small PVCs (2Gi) to conserve disk during demos.
- **Metrics/control-plane tweaks for k3d**: k3d cluster args bind control-plane metrics to 0.0.0.0 so Prometheus can scrape in a single-node lab; acceptable in lab, not in multi-tenant prod.
- **Resource sizing for laptops**: Many components single-replica with low CPU/memory requests/limits; persistence sizes minimal. Intended for local demos, not production load.
