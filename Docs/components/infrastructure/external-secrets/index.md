# external-secrets

![Version: latest](https://img.shields.io/badge/Version-latest-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://external-secrets.io)

Synchronize secrets from external sources into Kubernetes

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `latest` |
| **Chart Type** | `application` |
| **Upstream Project** | [external-secrets](https://external-secrets.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why External Secrets?

External Secrets Operator bridges Vault and Kubernetes. It watches ExternalSecret CRDs, pulls secrets from backends like Vault, and synchronizes them into standard Kubernetes Secrets. Applications consume those Secrets using normal patterns (environment variables, volume mounts), decoupled from the secret source.

This separation means:

- **Vault**: Stores and manages secrets, enforces access policies
- **External Secrets**: Handles synchronization
- **Applications**: Consume standard Kubernetes Secrets

The operator supports automatic updates. When a secret changes in Vault, External Secrets updates the Kubernetes Secret, enabling zero-downtime credential rotation.

External Secrets can pull from multiple backends (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault, Vault). While this platform uses Vault, the pattern remains portable.

## Architecture Role

External Secrets Operator sits at **Layer 2** of the platform, the Automation & Governance layer. It operates as a synchronization engine.

Key integration points:

- **Vault**: Authenticates via Kubernetes ServiceAccount and reads secrets from specified paths
- **Kubernetes Secrets**: Creates and updates Secrets based on ExternalSecret resources
- **ArgoCD**: Deploys ExternalSecret resources as part of application manifests
- **Applications**: Consume the synchronized secrets

The `creationPolicy: Merge` setting allows both Helm charts and External Secrets to manage the same Secret resource without conflict. Helm creates the Secret with default values, External Secrets merges in credentials from Vault.

See [Secrets Management](../../../concepts/secrets-management.md) for the complete flow.

## Configuration Values

The following table lists the configurable parameters:

## Values

### Performance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| concurrent | int | `5` | Concurrent ExternalSecret reconciliations for better performance |

### CRDs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| installCRDs | bool | `true` | Install CRDs. Should be true for the initial installation |

### General Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| priorityClassName | string | `"platform-infrastructure"` | Priority class for External Secrets Operator pods |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicas | int | `1` | Number of replicas for the operator |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe.enabled | bool | `false` | Enable liveness probe |
| readinessProbe.enabled | bool | `true` | Enable readiness probe |
| readinessProbe.spec.failureThreshold | int | `3` | Failure threshold for readiness probe |
| readinessProbe.spec.httpGet.path | string | `"/readyz"` | Readiness probe path |
| readinessProbe.spec.httpGet.port | int | `8081` | Readiness probe port |
| readinessProbe.spec.initialDelaySeconds | int | `20` | Initial delay before readiness probe |
| readinessProbe.spec.periodSeconds | int | `10` | Period between readiness probes |
| readinessProbe.spec.timeoutSeconds | int | `5` | Timeout for readiness probe |
| resources.limits.cpu | string | `"1000m"` | CPU limit |
| resources.limits.memory | string | `"1Gi"` | Memory limit |
| resources.requests.cpu | string | `"250m"` | CPU request |
| resources.requests.memory | string | `"256Mi"` | Memory request |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.name | string | `"external-secrets"` | Service account name |
| serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| serviceMonitor.honorLabels | bool | `true` | Honor labels from service |
| serviceMonitor.interval | string | `"60s"` | Scrape interval |
| serviceMonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| webhook.certManager.addInjectorAnnotations | bool | `true` | Automatically inject CA into webhooks and CRDs |
| webhook.certManager.cert.create | bool | `true` | Create certificate resource |
| webhook.certManager.cert.duration | string | `"2160h"` | Certificate lifetime (90 days) |
| webhook.certManager.cert.issuerRef.group | string | `"cert-manager.io"` | Issuer group |
| webhook.certManager.cert.issuerRef.kind | string | `"ClusterIssuer"` | Issuer kind |
| webhook.certManager.cert.issuerRef.name | string | `"ca-issuer"` | Issuer name |
| webhook.certManager.cert.privateKey.rotationPolicy | string | `"Always"` | Private key rotation policy |
| webhook.certManager.cert.renewBefore | string | `"720h"` | Renew certificate 30 days before expiry |
| webhook.certManager.enabled | bool | `true` | Enable cert-manager for webhook certificates |
| webhook.lookaheadInterval | string | `"168h"` | Certificate validity lookahead interval (must be less than cert.renewBefore) |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
