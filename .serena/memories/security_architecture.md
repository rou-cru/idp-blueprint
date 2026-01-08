# Security & Policy Architecture (validated 2025-12-27)

## Overview
- **Secrets**: Vault + External Secrets Operator (ESO)
- **Policy**: Kyverno + Policy Reporter
- **Vulnerability**: Trivy Operator

## Secrets Management
Sources: `IT/vault/values.yaml`, `Scripts/vault-init.sh`, `IT/external-secrets/*`, `K8s/*/*secretstore*.yaml`.

### Vault
- **Mode**: Standalone with Raft storage (`/vault/data`)
- **TLS**: `tls_disable="true"` in listener
- **Storage**: PVC size `1Gi`
- **Init/Unseal**: `Scripts/vault-init.sh` stores unseal key and root token in `vault-system/vault-init-keys`

### External Secrets Operator (ESO)
- **SecretStores**: Per-namespace SecretStores point to `http://vault.vault-system.svc.cluster.local:8200` and `path: secret` (v2)
- **Auth**: Kubernetes auth with roles `eso-<namespace>-role` via `external-secrets` ServiceAccount
- **ArgoCD**: `argocd-admin-password` ExternalSecret uses `creationPolicy: Merge` and `deletionPolicy: Retain`

## Policy Enforcement
Sources: `K8s/policies/applicationset-policies.yaml`, `K8s/policies/infrastructure/kyverno/*`, `K8s/policies/infrastructure/policy-reporter/values.yaml`.

- **Kyverno**: Deployed in `kyverno-system` via ApplicationSet
- **Policy Reporter**:
  - REST API enabled (`rest.enabled: true`)
  - UI disabled (`ui.enabled: false`)
  - Metrics enabled with `mode: detailed`
  - Grafana dashboards labeled `grafana_dashboard: "1"` in `kyverno-system`

## Vulnerability Scanning (Trivy)
Source: `K8s/security/trivy/values.yaml`.

- **Target workloads**: `replicaset,statefulset,daemonset,cronjob`
- **Excluded namespaces**: `kube-system,argocd,cert-manager,vault-system,kyverno-system`
- **Compliance**: `k8s-pss-baseline-0.1`
- **Built-in Trivy Server**: enabled (`builtInTrivyServer: true`)
