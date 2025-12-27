# Security & Policy Architecture (validated 2025-12-27)

## Overview
- **Secrets**: Vault (Central Store) + External Secrets Operator (ESO) (K8s Integration).
- **Policy**: Kyverno (Admission Control) + Policy Reporter (Observability).
- **Vulnerability**: Trivy Operator (Cluster Scanning).

## 1. Secrets Management
- **Vault**:
  - **Mode**: Standalone, TLS disabled (`tls_disable="true"`), unseal key in `vault-system/vault-init-keys` Secret (Demo config).
  - **Storage**: Raft (1Gi PVC).
  - **Seeding**: `Task/bootstrap.yaml` invokes `scripts/vault-init.sh` and `vault:generate-secrets` to seed demo credentials (from `.env`/`config.toml`) into `kv-v2` path `secret/`.
- **External Secrets Operator (ESO)**:
  - **SecretStores**: Configured per namespace, pointing to `http://vault.vault-system.svc.cluster.local:8200`.
  - **Authentication**: Kubernetes Auth (Vault roles `eso-<namespace>-role` bound to `external-secrets` SA).
  - **Pattern**: `ExternalSecret` -> (fetches from Vault) -> K8s `Secret`.
  - **ArgoCD**: Uses `creationPolicy: Merge` to inject admin secrets into the existing ArgoCD secret.

## 2. Policy Enforcement (Kyverno)
- **Engine**: Kyverno controllers in `kyverno-system`.
- **Policies**: Managed via `K8s/policies` AppSet.
- **Reporting**:
  - **Policy Reporter**: Deployed in `kyverno-system` (Headless, REST API enabled).
  - **Metrics**: Prometheus integration enabled (`detailed` mode).
  - **Dashboards**: ConfigMaps generated in `kyverno-system` (Label: `grafana_dashboard=1`).
  - **Issue**: Dashboards might not be visible if Grafana sidecar isn't configured to scan `kyverno-system`.

## 3. Vulnerability Scanning (Trivy)
- **Component**: `trivy-operator` + `trivy-server` in `security` namespace.
- **Scope**: Scans `replicaset,statefulset,daemonset,cronjob` (Pods excluded to reduce noise).
- **Exclusions**: `kube-system`, `argocd`, `cert-manager`, `vault-system`, `kyverno-system`.
- **Compliance**: `k8s-pss-baseline-0.1` profile enabled.
- **Reporting**: Generates `VulnerabilityReports` (CRDs); accessible via Grafana dashboards (UIDs `ycwPj724k`, `4SECJjm4z`).
