# Label Standards

This document defines the canonical label values and standards used
across the IDP Blueprint repository.

## Canonical Label Values

All resources in the platform should use these standard values for consistency:

### Business Labels

- **owner**: `platform-team`
- **business-unit**: `infrastructure`
- **environment**: `demo`

### Application Labels

- **app.kubernetes.io/part-of**: `idp`

## Label Requirements by Resource Type

### Namespaces (Required by Kyverno Policy: enforce-namespace-labels)

All namespaces MUST include:

```yaml
labels:
  app.kubernetes.io/part-of: idp
  owner: platform-team
  business-unit: infrastructure
  environment: demo
```

### Workloads (Audited by Kyverno Policy: require-component-labels)

Deployments, StatefulSets, and DaemonSets SHOULD include:

```yaml
labels:
  app.kubernetes.io/name: <component-name>
  app.kubernetes.io/instance: <instance-name>
  app.kubernetes.io/version: <version>
  app.kubernetes.io/component: <component-type>
```

### Other Resources

All other Kubernetes resources SHOULD include at minimum:

```yaml
labels:
  app.kubernetes.io/part-of: idp
  app.kubernetes.io/component: <component-type>
```

## Comment Style for Values Files

**Standard**: `# @section -- Section Name`

**Example**:

```yaml
# @section -- Global Configuration
# @description Global settings for the component

# -- Enable high availability mode
ha:
  enabled: false
```

**Rationale**: This style is compatible with helm-docs and provides
consistent documentation generation.

## Priority Classes Assignment

PriorityClasses are defined as code in `IT/priorityclasses/priorityclasses.yaml`
and are part of the scheduling model described in
[`Scheduling, Priority, and Node Pools`](../concepts/scheduling-nodepools.md).

Use them to express **relative importance** rather than absolute guarantees. The
main classes are:

- **platform-infrastructure** (`value: 1000000`) – Vault, ArgoCD, cert-manager,
  External Secrets Operator and other core control planes
- **platform-policy** (`value: 100000`) – Kyverno admission/background
  controllers
- **platform-security** (`value: 12000`) – Trivy security scanners
- **platform-observability** (`value: 10000`) – Prometheus, Loki, Fluent Bit,
  Policy Reporter and related telemetry
- **platform-cicd** (`value: 7500`) – long‑lived CI/CD services (Argo
  Workflows, SonarQube, backing databases)
- **platform-dashboards** (`value: 5000`) – Grafana, Alertmanager and other
  dashboards
- **user-workloads** (`value: 3000`) – user applications deployed via GitOps
- **cicd-execution** (`value: 2500`) – short‑lived CI/CD execution pods (e.g.
  workflow pods, ephemeral builds)
- **unclassified-workload** (`value: 0`, `globalDefault: true`) – default for
  any workload without an explicit PriorityClass

Guidelines:

- Platform components SHOULD set one of the `platform-*` PriorityClasses.
- CI/CD execution pods SHOULD use `cicd-execution`.
- User workloads MAY use `user-workloads` or rely on the global default
  `unclassified-workload`, depending on environment guarantees.

## External Secrets RefreshInterval Strategy

| Interval | Use Case | Examples | Rationale |
|----------|----------|----------|-----------|
| 1h | Rarely-changed secrets | ArgoCD admin password | Minimize API calls to Vault |
| 5m | Infrastructure secrets | Certificate credentials | Balance between freshness and load |
| 3m | Application secrets | SonarQube tokens, Grafana credentials | Higher change frequency |

**Guidelines**:

- Use `1h` for bootstrap/admin secrets that are manually rotated
- Use `5m` for infrastructure components (default for most cases)
- Use `3m` for application-level secrets that may rotate programmatically
- Never use `<1m` to avoid overwhelming Vault API

## ArgoCD Sync Wave Annotations

Sync waves control deployment order in ArgoCD:

For the full wave model used in this repository, see
[`GitOps, Policy, and Eventing`](../concepts/gitops-model.md).

| Wave | Resources | Purpose |
|------|-----------|---------|
| -3 | IT namespaces | Bootstrap namespaces for infrastructure |
| -2 | K8s governance namespaces | Application namespaces with resource quotas |
| -1 | Priority classes, RBAC | Platform-wide configurations |
| 0 | Standard applications | Default deployment order |

## Annotations

### Common Annotations

```yaml
annotations:
  contact: platform-team
  documentation: https://github.com/rou-cru/idp-blueprint
  description: "<Brief description of the resource>"
```

### ArgoCD-specific Annotations

```yaml
annotations:
  argocd.argoproj.io/sync-wave: "<wave-number>"
  argocd.argoproj.io/sync-options: "SkipDryRunOnMissingResource=true"
```

## Validation

All changes should be validated against:

1. Kyverno policies in `Policies/rules/`
2. Kustomize build: `kustomize build <directory>`
3. Helm lint: `helm lint --values <values-file>`
4. The validation script: `scripts/validate-consistency.sh`

## References

- [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- [Kyverno Best Practices](https://kyverno.io/policies/)
- [ArgoCD Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
