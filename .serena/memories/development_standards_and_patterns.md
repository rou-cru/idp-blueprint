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
  - `platform-critical`: Core components (Cilium, Vault).
  - `platform-infrastructure`: Supporting infra (ArgoCD, Cert-Manager).
  - `platform-observability`: Monitoring stack.
  - `platform-dashboards`: UI components (Backstage).
  - `platform-workloads`: Default for user workloads.
- **Requests & Limits**:
  - Must be explicitly set.
  - CPU in `m`, Memory in `Mi` or `Gi`.

## 4. Secrets Management Pattern
- **Access**: Workloads do **not** mount Vault directly.
- **Flow**:
  1. Define a `SecretStore` in `infrastructure/` pointing to Vault (Role: `eso-<namespace>-role`).
  2. Create an `ExternalSecret` resource referencing the Vault path.
  3. ESO creates a native Kubernetes `Secret`.
  4. Workload mounts the native `Secret`.
- **Policy**: Default `creationPolicy: Owner` (Secret deleted with ExternalSecret).

## 5. Verification & Tooling
- **Validation**:
  - `task utils:config:print`: View resolved configuration.
  - `helm template .`: Verify chart rendering locally.
- **Documentation**:
  - `task docs`: Regenerates documentation site.
  - `task docs:helm`: Updates Helm chart READMEs.
  - `task docs:metadata`: Updates `Catalog/components/*.yaml` metadata.
