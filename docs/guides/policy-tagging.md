# Kubernetes Labeling Standards for Policies

> **Note:** This guide has been consolidated into the complete labeling standards documentation.
> For comprehensive information about labels, annotations, priority classes, sync waves,
> and validation, please see the [Kubernetes Labeling Standards](../reference/labels-standard.md).

## Overview

All resources in the IDP Blueprint platform use standardized labels to ensure:

- **Operational consistency** across all components
- **Policy enforcement** via Kyverno
- **Resource governance** with quotas and limits
- **GitOps automation** with ArgoCD sync waves
- **Observability** and monitoring

## Quick Reference

### Business Labels (Required on Namespaces)

| Label | Value | Purpose |
|-------|-------|---------|
| `owner` | `platform-team` | Team responsible for the resource |
| `business-unit` | `infrastructure` | Business unit for cost allocation |
| `environment` | `demo` | Environment classification |

### Application Labels (Kubernetes Recommended)

| Label | Example | Purpose |
|-------|---------|---------|
| `app.kubernetes.io/part-of` | `idp` | Parent application/platform |
| `app.kubernetes.io/name` | `vault` | Component name |
| `app.kubernetes.io/instance` | `vault-demo` | Instance identifier |
| `app.kubernetes.io/version` | `1.15.0` | Version of the component |
| `app.kubernetes.io/component` | `database` | Role within the architecture |

## Using Labels with Policies

When creating Kyverno policies that leverage these labels:

1. **Namespace Propagation**: Labels defined on namespaces are automatically propagated
   to workloads by Kyverno policies (`Policies/rules/enforce-namespace-labels.yaml`)

2. **Validation**: Policies validate that required labels are present
   - `enforce-namespace-labels.yaml`: Enforces business labels on namespaces
   - `require-component-labels.yaml`: Audits application labels on workloads

3. **Label Selectors**: Use label selectors in policy rules to target specific resources:
   ```yaml
   match:
     any:
       - resources:
           kinds:
             - Deployment
           selector:
             matchLabels:
               app.kubernetes.io/part-of: idp
   ```

## Complete Documentation

For the full specification including:

- **Priority Classes Assignment** for resource scheduling
- **External Secrets RefreshInterval Strategy** for secret synchronization
- **ArgoCD Sync Wave Annotations** for deployment ordering
- **Complete Validation Rules** with Kyverno examples
- **Label propagation details**

Please refer to the [Kubernetes Labeling Standards](../reference/labels-standard.md) documentation.

## See Also

- [Architecture: Applications](../architecture/applications.md) - How labels are used in GitOps
- [Kyverno Policies](../components/policy/kyverno/index.md) - Policy enforcement details
- [Contributing Guide](contributing.md) - How to contribute with proper labeling
