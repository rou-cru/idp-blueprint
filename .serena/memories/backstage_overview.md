# Backstage — Architecture, Config & Runtime (validated 2025-12-27)

## Deployment model (repo)
- AppSet: `K8s/backstage/applicationset-backstage.yaml` deploys `backstage/`, `dex/`, `governance/`, `infrastructure/`.
- AppSet patches `idp-vars-backstage` and `idp-vars-dex` with `DNS_SUFFIX`, GitHub org/repo/branch/token, `CLUSTER_NAME`.

## Backstage chart configuration (repo)
- Chart values: `K8s/backstage/backstage/values.yaml`.
- Backstage image: `roucru/idp-blueprint-dev-portal:latest`.
- Extra app config: `backstage-app-config-override` ConfigMap (rendered from template).
- Extra secrets: `backstage-app-secrets` injected via `extraEnvVarsSecrets`.
- Init container waits for Dex OIDC endpoint before starting Backstage.
- PostgreSQL enabled in‑chart, StatefulSet `backstage-postgresql` with 8Gi PVC.

## Rendered config path (repo + cluster)
- Template: `K8s/backstage/backstage/templates/cm-tpl.yaml`.
- Renderer job replaces `backstage-app-config-override` with values from `idp-vars-backstage`.
- Live ConfigMap in cluster contains resolved URLs:
  - `https://backstage.<DNS_SUFFIX>`
  - `https://dex.<DNS_SUFFIX>`
  - `https://grafana.<DNS_SUFFIX>`

## Key integrations (repo + cluster)
- **OIDC**: Dex provider configured in rendered app-config; Backstage uses OIDC sign-in.
- **GitHub catalog provider**: pulls `Catalog/**/*.yaml` from configured org/repo/branch.
- **ArgoCD**: backend plugin configured with in-cluster URL `http://argocd-server.argocd.svc.cluster.local`.
- **Kubernetes plugin**: `serviceLocatorMethod: multiTenant`, cluster locator uses in-cluster service account.
- **Policy Reporter**: proxy route `/policy-reporter` → `policy-reporter.kyverno-system.svc.cluster.local:8080`.
- **Grafana**: `grafana.domain` set for plugin usage (see `backstage_grafana_integration` memory for dashboards).
- **TechDocs**: builder `local`, generator `docker`, publisher `local`.

## UI plugins (repo)
- Catalog, Catalog Graph, TechDocs, Scaffolder, API Docs, Search, Notifications, Signals.
- Policy Reporter UI route `/policy-reporter` enabled.
- Topology page used on entity layouts.

## Runtime status (cluster)
- Namespace `backstage`:
  - Deployments: `backstage`, `dex` (ready).
  - StatefulSet: `backstage-postgresql` (ready).
  - Service: `backstage` on port 7007 (ClusterIP).
- `backstage-app-config-override` is rendered with DNS_SUFFIX values.
- `backstage-app-secrets` exists (contains ARGOCD creds, OIDC client secret, backend secret, GitHub token) — values are demo and must be rotated for real use.