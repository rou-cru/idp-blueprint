# Backstage Architecture & Integration (validated 2025-12-27)

## 1. Deployment Model
- **ApplicationSet**: `K8s/backstage/applicationset-backstage.yaml` deploys the stack (`backstage`, `dex`, `governance`, `infrastructure`).
- **Configuration Injection**: The AppSet patches `idp-vars-backstage` and `idp-vars-dex` (ConfigMaps) with dynamic values from `.env` (`DNS_SUFFIX`, `CLUSTER_NAME`, GitHub Creds) during the ArgoCD generation phase.

## 2. Component Configuration (`K8s/backstage/backstage/values.yaml`)
- **Image**: `roucru/idp-blueprint-dev-portal:latest`.
- **Database**: In-chart PostgreSQL enabled (`backstage-postgresql` StatefulSet, 8Gi PVC).
- **Initialization**: Init container (`roucru/idp-blueprint:ops`) waits for Dex OIDC endpoint to be ready before starting Backstage.
- **ServiceAccount**: `backstage-kubernetes` (used for K8s plugin cluster locator).

## 3. Configuration Management
- **Base Config**: `app-config.yaml` baked into the image.
- **Dynamic Override**:
  - **Template**: `K8s/backstage/backstage/templates/cm-tpl.yaml`.
  - **Rendering**: A Kubernetes Job (`backstage-config-renderer`) reads `idp-vars-backstage`, substitutes placeholders (e.g., `${DNS_SUFFIX}`), and updates the `backstage-app-config-override` ConfigMap.
  - **Mount**: Backstage mounts this ConfigMap to overlay runtime values.
- **Secrets**: `backstage-app-secrets` (seeded by Vault/External Secrets) injected via `extraEnvVarsSecrets`.

## 4. Key Integrations
- **Authentication (OIDC)**:
  - Provider: Dex (`https://dex.${DNS_SUFFIX}`).
  - Flow: OIDC / OAuth2.
- **Catalog**:
  - **GitHub Provider**: Ingests entities from `Catalog/**/*.yaml` in the configured repo (`${GITHUB_ORG}/${GITHUB_REPO}`).
- **Plugins**:
  - **Kubernetes**: `multiTenant` locator uses the in-cluster ServiceAccount.
  - **ArgoCD**: Backend plugin talks to `http://argocd-server.argocd.svc.cluster.local`.
  - **Policy Reporter**: Proxy route configured to `http://policy-reporter.kyverno-system.svc.cluster.local:8080`.
  - **Grafana**: Integrated via `grafana.domain` (dashboards discovery).
  - **TechDocs**: Local builder/publisher (uses Docker).

## 5. UI & Plugins
- **Core**: Catalog, Scaffolder, TechDocs, Search, API Docs.
- **Extensions**: Catalog Graph, Policy Reporter UI, Topology, Notifications, Signals.
