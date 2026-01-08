# Development Standards & Patterns (validated 2025-12-27)

## 1. Application Packaging (GitOps)
- **Pattern**: Every stack (e.g., `observability`, `backstage`) has a dedicated directory in `K8s/<stack>/`.
- **Structure**:
  - `applicationset-<stack>.yaml`: Defines how the stack is deployed (Git Generator over subdirectories).
  - `<component>/`: Contains the Helm Chart (`Chart.yaml` + `values.yaml`) or raw manifests.
  - `governance/`: Namespace definitions, ResourceQuotas, LimitRanges.
  - `infrastructure/`: Stack-specific infrastructure (e.g., SecretStores, common ConfigMaps).

## 2. Labeling Standards
- **Source of Truth**: `Docs/src/content/docs/reference/labels-standard.mdx`.
- **Mandatory Labels** (for Namespaces and key resources):
  - `app.kubernetes.io/part-of: idp`
  - `owner: <team>` (e.g., `platform-team`)
  - `business-unit: <unit>` (e.g., `infrastructure`)
  - `environment: <env>` (e.g., `demo`)

## 3. Resource Management
- **PriorityClasses** (`IT/priorityclasses/`):
  | Class | Value | Use Case | Examples |
  | :--- | :--- | :--- | :--- |
  | `platform-infrastructure` | 1000000 | Core control plane | Vault, ArgoCD, Cert-Manager, External Secrets |
  | `platform-events` | 200000 | Event mesh | Argo Events controller, EventBus, webhooks |
  | `platform-policy` | 100000 | Policy enforcement | Kyverno admission & background controllers |
  | `platform-security` | 12000 | Security scanning | Trivy vulnerability scanners |
  | `platform-observability` | 10000 | Monitoring | Prometheus, Loki, Fluent Bit, Policy Reporter |
  | `platform-cicd` | 7500 | CI/CD services | Argo Workflows controller/server, SonarQube, databases |
  | `platform-dashboards` | 5000 | Visualization | Grafana, Alertmanager, Backstage UI |
  | `user-workloads` | 3000 | User applications | Apps deployed via GitOps |
  | `cicd-execution` | 2500 | Ephemeral builds | Workflow pods, Kaniko builds, short-lived jobs |
  | `unclassified-workload` | 0 (globalDefault) | Experimental/test | Default for unspecified workloads |

- **Requests & Limits**:
  - Must be explicitly set.
  - CPU in `m`, Memory in `Mi` or `Gi`.
  - Example: `requests.cpu: 300m`, `limits.memory: 1Gi`

## 4. Secrets Management Pattern
- **Access**: Workloads do **not** mount Vault directly.
- **Flow**:
  1. Define a `SecretStore` in `infrastructure/` pointing to Vault (Role: `eso-<namespace>-role`).
  2. Create an `ExternalSecret` resource referencing the Vault path.
  3. ESO creates a native Kubernetes `Secret`.
  4. Workload mounts the native `Secret`.
- **Policy**: Default `creationPolicy: Owner` (Secret deleted with ExternalSecret).

## 4.5. Secrets RefreshInterval Strategy (Actual Implementation)
The refreshInterval determines how frequently ExternalSecrets poll Vault for updates. The actual implementation varies by secret type:

| Interval | Use Case | Examples in Code |
| :--- | :--- | :--- |
| **1h** | Stable bootstrap secrets | `dex-externalsecret.yaml` (Dex client secret) |
| **1h** | Backstage app secrets | `backstage-app-externalsecret.yaml` (Backend, GitHub token) |
| **3m** | Application credentials | `grafana-admin-externalsecret.yaml`, `sonarqube-admin-externalsecret.yaml` |
| **3m** | ArgoCD admin password | `argocd-admin-externalsecret.yaml` (Critical for emergency access) |
| **30s-1m** | (Not used) | **Avoid** to prevent overwhelming Vault API |

**Guidelines from Implementation:**
- Use `1h` for secrets that change rarely (bootstrap, infrastructure)
- Use `3m` for application-level credentials (Grafana, SonarQube, ArgoCD)
- Balance freshness vs. API load on Vault
- Never use intervals `< 1m` in production

## 4.6. Special CreationPolicy Cases
While `creationPolicy: Owner` is the default, some scenarios require different policies:

- **`creationPolicy: Merge`**: Preserves existing secret data while updating specific keys
  - **Use Case**: ArgoCD admin password (preserves `server.secretkey`)
  - **File**: `IT/external-secrets/argocd-admin-externalsecret.yaml`
- **`creationPolicy: Orphan`**: Creates secret but doesn't manage its lifecycle
- **`deletionPolicy: Retain`**: Keeps secret even if ExternalSecret is deleted

## 5. Verification & Tooling
- **Validation**:
  - `task config:print`: View resolved configuration from config.toml.
  - `helm template .`: Verify chart rendering locally.
  - `Scripts/validate-consistency.sh`: Run full consistency validation.
- **Documentation Tasks**:
  - `task docs`: Regenerates all documentation (metadata + helm docs).
  - `task docs:helm`: Updates Helm chart READMEs using helm-docs.
  - `task docs:metadata`: Updates `Catalog/components/*.yaml` metadata.
  - `task docs:linkcheck`: Checks for broken documentation links.
  - `task docs:astro:build`: Builds Astro documentation site.
