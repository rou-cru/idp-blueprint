# kyverno

![Version: 3.5.2](https://img.shields.io/badge/Version-3.5.2-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://kyverno.io)

Kubernetes-native policy management and security engine

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `3.5.2` |
| **Chart Type** | `application` |
| **Upstream Project** | [kyverno](https://kyverno.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Kyverno?

Kyverno uses Kubernetes-native resources (policies are CRDs, like any other manifest) and doesn't require learning a specialized language like Rego. Policies are written in YAML, which means the learning curve is lower if you already understand Kubernetes manifests.

Beyond validation, Kyverno supports:

- **Validation**: Accept or reject resources based on rules
- **Mutation**: Modify resources on admission (e.g., inject labels, add sidecars)
- **Generation**: Create new resources when a trigger resource is created (e.g., generate NetworkPolicy for every new namespace)
- **Image Verification**: Validate container image signatures using Sigstore/Cosign

The platform currently uses Kyverno primarily for validation. The mutation and generation capabilities are available for future use as governance requirements evolve. Kyverno also integrates with FinOps tools like Kubecost.

## Architecture Role

Kyverno operates at **Layer 2** of the platform, the Automation & Governance layer. It sits in the admission control path, evaluating every resource before it's persisted to etcd.

Key integration points:

- **Kubernetes API**: Kyverno registers as a validating and mutating webhook
- **ArgoCD**: Policies evaluate resources that ArgoCD deploys
- **PolicyReport CRDs**: Kyverno generates reports that Policy Reporter consumes
- **Prometheus**: Exposes metrics on policy evaluations, violations, and webhook performance

Most policies currently run in `audit` mode, meaning violations are reported but don't block deployments. This follows the "paved road" philosophy: guide users toward best practices without creating friction. The exception is `enforce-namespace-labels`, which runs in `enforce` mode to guarantee that all namespaces have the metadata required for cost attribution and governance.

See [Security & Policy Model](../../../concepts/security-policy-model.md) for the platform's governance architecture.

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backgroundController.resources.limits.cpu | string | `"250m"` |  |
| backgroundController.resources.limits.memory | string | `"256Mi"` |  |
| backgroundController.resources.requests.cpu | string | `"100m"` |  |
| backgroundController.resources.requests.memory | string | `"128Mi"` |  |
| cleanupController.resources.limits.cpu | string | `"250m"` |  |
| cleanupController.resources.limits.memory | string | `"256Mi"` |  |
| cleanupController.resources.requests.cpu | string | `"100m"` |  |
| cleanupController.resources.requests.memory | string | `"128Mi"` |  |
| crds.install | bool | `true` |  |
| livenessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probe for the main admission controller. |
| priorityClassName | string | `"platform-policy"` | Priority class for Kyverno admission controller |
| readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Readiness probe for the main admission controller. |
| reportsController.resources.limits.cpu | string | `"250m"` |  |
| reportsController.resources.limits.memory | string | `"256Mi"` |  |
| reportsController.resources.requests.cpu | string | `"100m"` |  |
| reportsController.resources.requests.memory | string | `"128Mi"` |  |
| resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resources for the main admission controller. |
| startupProbe | object | `{"failureThreshold":30,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Startup probe for the main admission controller. |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
