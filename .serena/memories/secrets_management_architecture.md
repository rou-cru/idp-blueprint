# Secrets Management Architecture (validated 2025-12-27)

## Pattern & demo posture
- Vault + External Secrets Operator (ESO) is the source of truth for runtime secrets.
- `config.toml` includes demo credentials (GitHub token, registry creds, default passwords). These are seeded into Vault during deployment; **must be rotated/emptied for real use**.
- Vault runs standalone with TLS disabled (`tls_disable = "true"`) in demo (`IT/vault/values.yaml` and runtime config).
- Vault init stores unseal key + root token in Secret `vault-init-keys` (namespace `vault-system`).

## Vault init & engines (repo)
- `Scripts/vault-init.sh` enables: kv-v2 (`secret`), database, transit.
- Policy `eso-policy` grants broad access to `secret/*`.
- Roles created: `eso-argocd-role`, `eso-cicd-role`, `eso-observability-role`, `eso-backstage-role`.

## Secret seeding (repo)
- `Task/bootstrap.yaml` runs `vault:init` then `vault:generate-secrets`.
- `vault:generate-secrets` writes:
  - ArgoCD admin (bcrypt + plain).
  - Grafana admin.
  - SonarQube admin + monitoring passcode.
  - Docker registry creds.
  - Backstage app secrets + backstage postgres creds.
- `Scripts/vault-generate.sh`: empty vars → random 32B base64; supports base64/hex and bcrypt for ArgoCD.

## ESO & SecretStores (repo)
- ESO chart in `IT/external-secrets/values.yaml` with ServiceMonitor and webhook TLS via cert‑manager.
- SecretStore per namespace → `http://vault.vault-system.svc.cluster.local:8200` (demo HTTP) with role `eso-<ns>-role`.
- ArgoCD ExternalSecret uses `creationPolicy: Merge` + `deletionPolicy: Retain`; others use Owner.

## Metrics presence (cluster)
- External Secrets metrics exist in Prometheus:
  - `externalsecret_status_condition`, `externalsecret_sync_calls_*`, `externalsecret_reconcile_duration`, `externalsecret_provider_api_calls_count`.

## Demo vs production guidance
- **Demo**: TLS off, root token in cluster, wide ESO policy, seeded demo creds.
- **Production**: enable TLS, use HA/auto‑unseal, remove demo creds from `config.toml`, tighten policies per namespace, add NetworkPolicies.
