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

## 6. Additional Implementation Details

### Configuration Loading Fallback
The configuration renderer includes a fallback mechanism for development and manual testing:
- **Primary Loading**: Variables are loaded from individual files in `/vars/` (DNS_SUFFIX, CLUSTER_NAME, GITHUB_ORG, GITHUB_REPO, GITHUB_BRANCH)
- **Fallback Mechanism**: If `/vars/env` file exists, the job executes `source /vars/env` to load additional variables (see job-renderer.yaml lines 118-121)
- **Purpose**: Enables manual testing scenarios and local development overrides

### Security Annotations (Checkov)
The configuration renderer job includes explicit security policy exceptions with justifications:
```yaml
annotations:
  checkov.io/skip1: CKV_K8S_38=Job needs SA token to run kubectl apply in-cluster
  checkov.io/skip2: CKV_K8S_43=Dev tag moves frequently; digest not pinned during active development
  checkov.io/skip3: CKV_K8S_15=Intentionally IfNotPresent to avoid repeated pulls of ops image
```
- **CKV_K8S_38**: Job requires ServiceAccount token for in-cluster kubectl operations
- **CKV_K8S_43**: Using mutable tags during active development (not for production)
- **CKV_K8S_15**: IfNotPresent pull policy to optimize development workflow

### Vault Authentication Details
The SecretStore configuration includes specific Vault authentication parameters:
- **Vault Server**: `http://vault.vault-system.svc.cluster.local:8200`
- **Auth Method**: Kubernetes authentication with service account `external-secrets`
- **Role**: `eso-backstage-role` for Vault access
- **Audiences**: Explicitly configured as `vault` for OIDC authentication (see backstage-secretstore.yaml lines 33-34)
- **Purpose**: Ensures proper authentication flow between ESO and Vault in kubernetes environments
