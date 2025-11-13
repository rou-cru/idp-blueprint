# Secrets Management

Vault is the single source of truth for secrets. External Secrets Operator (ESO) fetches from Vault and writes Kubernetes Secrets in each namespace. Workloads only consume Kubernetes Secrets.

## Components

- Vault (namespace `vault-system`) initialized and configured by `task bootstrap:vault:init`
- External Secrets Operator (namespace `external-secrets-system`) with cert-manager webhook
- Per-namespace `ServiceAccount` and `SecretStore` that bind to Vault via Kubernetes auth
- `ExternalSecret` objects that declare which Vault paths/keys to sync

## Flow

```d2
direction: right

VaultSystem: {
  label: "vault-system"
  Vault: "Vault (KV v2: secret/*)"
}

ESOSystem: {
  label: "external-secrets-system"
  ESO: "External Secrets Operator"
}

Namespaces: {
  Argocd: {
    label: "argocd"
    SA: "ServiceAccount: external-secrets"
    Store: "SecretStore: vault-backend"
    ES: "ExternalSecret: argocd-admin-password → argocd-secret (Merge)"
  }
  Observability: {
    label: "observability"
    SA: "ServiceAccount: external-secrets"
    Store: "SecretStore: observability"
    ES: "ExternalSecret: grafana-admin-credentials"
  }
  CICD: {
    label: "cicd"
    SA: "ServiceAccount: external-secrets"
    Store: "SecretStore: cicd"
    ES1: "ExternalSecret: sonarqube-admin"
    ES2: "ExternalSecret: sonarqube-monitoring-passcode"
  }
}

ESOSystem.ESO -> Namespaces.Argocd.ES: watches
ESOSystem.ESO -> Namespaces.Observability.ES
ESOSystem.ESO -> Namespaces.CICD.ES1
ESOSystem.ESO -> Namespaces.CICD.ES2

Namespaces.Argocd.Store -> VaultSystem.Vault
Namespaces.Observability.Store -> VaultSystem.Vault
Namespaces.CICD.Store -> VaultSystem.Vault
```

## Repo wiring

- ESO install: IT/external-secrets (values in `eso-values.yaml`)
- Vault install: IT/vault; initialization by `Scripts/vault-init.sh`
- Vault roles for ESO (created by init script): `eso-argocd-role`, `eso-observability-role`, `eso-cicd-role`
- ArgoCD namespace:
  - SecretStore: IT/external-secrets/argocd-secretstore.yaml
  - ExternalSecret: IT/external-secrets/argocd-admin-externalsecret.yaml (target `argocd-secret`, `creationPolicy: Merge` to preserve `server.secretkey`)
- Observability namespace:
  - ServiceAccount + SecretStore: K8s/observability/infrastructure/{eso-observability,observability-secretstore}.yaml
  - ExternalSecret: K8s/observability/kube-prometheus-stack/grafana-admin-externalsecret.yaml
- CICD namespace:
  - ServiceAccount + SecretStore: K8s/cicd/infrastructure/{eso-cicd,cicd-secretstore}.yaml
  - ExternalSecret: K8s/cicd/sonarqube/*.yaml

## Operations

- Initialize Vault (demo): `task bootstrap:vault:init`
- Generate demo secrets into Vault: `task bootstrap:vault:generate-secrets`
- Inspect sync status:
  - `kubectl get externalsecrets,secretstores -A`
  - `kubectl logs -n external-secrets-system deploy/external-secrets`
- Read synced secret:
  - `kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d; echo`

## Security notes

- No secret literals in manifests; all values live in Vault
- Demo defaults can be set via `config.toml`; empty values trigger random generation
- Restrict ServiceAccounts and Vault roles in production; prefer TLS for Vault endpoint
- Use `creationPolicy: Merge` when updating existing Secrets with internal keys (ArgoCD)
