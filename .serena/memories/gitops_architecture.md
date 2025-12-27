# GitOps Architecture (validated 2025-12-27)

## Layers
- **Bootstrap (Imperative)**: `Taskfile.yaml` executes `k3d:create` → namespaces/CRDs/SA/PriorityClasses → Cilium → cert-manager+Vault → ESO → ArgoCD → Gateway (`Task/bootstrap.yaml`). Imperative to avoid chicken‑egg scenarios (ArgoCD doesn't install itself).
- **Policies (AppSet)**: Policies reside in `K8s/policies/` and are deployed via `applicationset-policies.yaml` (no `Policies/` dir in repo root). The AppSet uses a Git generator (`K8s/policies/*`), project `policies`, destination `kyverno-system`. SyncPolicy includes prune/selfHeal + ServerSideApply/PruneLast/ApplyOutOfSyncOnly/RespectIgnoreDifferences and retry limit 10.
- **Stacks (AppSets)**: ApplicationSets in `K8s/*/applicationset-*.yaml` for `observability`, `backstage`, `cicd`, `security`, `events`. Git generator `K8s/<stack>/*`, template `<stack>-{{path.basename}}`, project=`<stack>`, destination namespace varies by stack. `IgnoreDifferences` often includes webhook CA bundles, Secrets, ServiceAccount secrets, and ExternalSecret status.

## Applications by Stack
- **observability**: fluent-bit, governance, infrastructure, kube-prometheus-stack, loki, pyrra, slo.
- **backstage**: infrastructure, governance, dex, backstage.
- **cicd**: infrastructure, governance, argo-workflows, sonarqube (Note: `fuses.cicd` defaults to `false` in `config.toml`).
- **security**: governance, trivy.
- **events**: governance, argo-events.
- **policies**: Git generator over `K8s/policies/*`.

## AppProjects
- Defined in individual files within `IT/argocd/`: `appproject-backstage.yaml`, `appproject-cicd.yaml`, `appproject-events.yaml`, `appproject-observability.yaml`, `appproject-policies.yaml`, `appproject-security.yaml`.

## Secrets Management (GitOps Pattern)
- **Flow**: Vault → SecretStore (per namespace) → ExternalSecret → Secret.
- **API**: `external-secrets.io/v1`.
- **Configuration**:
  - Fixed ServiceAccount `external-secrets`.
  - Vault roles `eso-<namespace>-role` configured via `Scripts/vault-init.sh`.
  - Demo SecretStore: `http://vault.vault-system.svc.cluster.local:8200`, path `secret`, version v2.
  - Examples: `IT/external-secrets/argocd-secretstore.yaml`, `K8s/cicd/infrastructure/cicd-secretstore.yaml`.
- **ArgoCD Integration**: The `argocd-admin-externalsecret.yaml` uses `creationPolicy: Merge` + `deletionPolicy: Retain`. Most others use `Owner`.

## Demo Simplifications
- **ArgoCD**: `server.insecure: true` (TLS termination handled by Gateway).
- **Credentials**: Passwords and Repo URLs injected via `.env` substitution in AppSets.
- **DNS**: `nip.io` used for local resolution.
- **Labels**: Common labels only where explicitly declared in charts/manifests; no mandatory global injection.

## Disaster Recovery / Flow
- `task destroy`: Deletes the cluster.
- `task deploy`: Recreates cluster and syncs apps from Git.
- **Vault**: Requires re-seeding via `task vault:generate-secrets` (or `task bootstrap:it:deploy-secret-and-certs`) after initialization.
