# Label Standards

This document defines the canonical label values and standards used across the IDP Blueprint repository.

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

**Rationale**: This style is compatible with helm-docs and provides consistent documentation generation.

## Priority Classes Assignment

Priority classes should be assigned based on component criticality:

### platform-critical (Value: 1000000000)
Reserved for system-critical components.

### platform-infrastructure (Value: 900000)
- argocd
- cert-manager
- vault
- external-secrets
- kyverno

### platform-observability (Value: 800000)
- prometheus
- grafana
- loki
- fluent-bit
- policy-reporter

### platform-cicd (Value: 700000)
- jenkins
- sonarqube
- argo-workflows

### platform-security (Value: 750000)
- trivy

### platform-default (Value: 0)
Default for application workloads.

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
