# Demo-Mode Tradeoffs (validated 2025-12-27)

Conscious choices made to keep the demo deployable on laptop-class hardware; **not production-ready**:

- **Config credentials in Git**: `config.toml` ships with known/demo creds (GitHub token, registry user/pass, ArgoCD/Grafana/SonarQube/Backstage Dex). Used to seed Vault quickly; must be blank/rotated for real use.
- **Vault relaxed posture**: Standalone, TLS disabled (`tls_disable="true"`), unseal/root token stored in K8s Secret; key-shares=1/threshold=1.
- **Gateway via NodePort + nip.io**: k3d host port mapping 30080/30443 and nip.io wildcard; no LoadBalancer/L2 announcements.
- **envsubst client-side**: Dynamic values (DNS_SUFFIX, NodePorts, repo/branch) rendered locally; manifests aren’t pure GitOps; kept for portability across LAN IPs.
- **Backstage simplified**: URLs rendered via job/placeholders; demo secrets; no corporate SSO/RBAC hardening.
- **Observability retention**: Loki filesystem backend with **24h retention** and small PVCs (2Gi) to conserve disk.
- **Control-plane metrics in k3d**: binds metrics to 0.0.0.0 for single-node lab scraping; not for multi-tenant prod.
- **Resource sizing for laptops**: many components single-replica with low requests/limits and minimal persistence.