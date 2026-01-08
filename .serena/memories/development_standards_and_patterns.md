# Development Standards & Patterns (validated 2025-12-27)

## GitOps Stack Layout
Each stack lives under `K8s/<stack>/` and is deployed by an ApplicationSet.

Common structure (when applicable):
- `applicationset-<stack>.yaml` (Git generator over stack subdirectories)
- `<component>/` (Helm chart or raw manifests)
- `governance/` (namespaces, quotas, limits)
- `infrastructure/` (SecretStores, shared ConfigMaps)

## Label Standards
Source of truth: `Docs/src/content/docs/reference/labels-standard.mdx`.

Namespaces must include:
- `app.kubernetes.io/part-of: idp`
- `owner: platform-team`
- `business-unit: infrastructure`
- `environment: demo`

Workloads should include the recommended `app.kubernetes.io/*` labels per the same doc.

## Priority Classes
Defined in `IT/priorityclasses/priorityclasses.yaml`:
- `platform-infrastructure`, `platform-events`, `platform-policy`, `platform-security`,
  `platform-observability`, `platform-cicd`, `platform-dashboards`
- `user-workloads`, `cicd-execution`, `unclassified-workload`

## External Secrets Refresh Intervals
Guidelines from `Docs/src/content/docs/reference/labels-standard.mdx`:
- `1h`: bootstrap/admin secrets
- `5m`: infrastructure secrets
- `3m`: application secrets
- Avoid `<1m` to reduce Vault load

## ApplicationSet Sync/Retry Defaults
ApplicationSets use automated sync (prune + selfHeal) and retry backoff:
- `limit: 10`, `duration: 10s`, `factor: 2`, `maxDuration: 10m`

## Validation & Tooling
- `task utils:config:print` (effective config)
- `task quality:check` (lint + validation + security scans)
- `Scripts/validate-consistency.sh` (label/structure consistency checks)
