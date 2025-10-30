# external-secrets

This document lists the configuration parameters for the `external-secrets` component.

## Values

### Performance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| concurrent | int | `5` | Concurrent ExternalSecret reconciliations for better performance |

### CRDs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| installCRDs | bool | `true` | Install CRDs. Should be true for the initial installation |

### Health Probes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe | object | `{"enabled":false}` | Liveness probe configuration |

### General Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| priorityClassName | string | `"platform-infrastructure"` | Priority class for External Secrets Operator pods |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicas | int | `1` | Number of replicas for the operator |

### Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"256Mi"}}` | Resource requests and limits for the operator pod |

### RBAC

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount | object | `{"create":true,"name":"external-secrets"}` | Service account configuration |

### Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceMonitor | object | `{"enabled":true,"honorLabels":true,"interval":"60s","scrapeTimeout":"40s"}` | ServiceMonitor configuration for Prometheus |

### Webhook

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| webhook | object | `{"certManager":{"addInjectorAnnotations":true,"cert":{"create":true,"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"ClusterIssuer","name":"ca-issuer"},"privateKey":{"rotationPolicy":"Always"},"renewBefore":"720h"},"enabled":true},"lookaheadInterval":"168h"}` | Webhook configuration with cert-manager integration |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe.enabled | bool | `false` | Enable liveness probe |
| readinessProbe | object | `{"enabled":true,"spec":{"failureThreshold":3,"httpGet":{"path":"/readyz","port":8081},"initialDelaySeconds":20,"periodSeconds":10,"timeoutSeconds":5}}` | Readiness probe configuration |
| readinessProbe.enabled | bool | `true` | Enable readiness probe |
| readinessProbe.spec | object | `{"failureThreshold":3,"httpGet":{"path":"/readyz","port":8081},"initialDelaySeconds":20,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe specification |
| readinessProbe.spec.failureThreshold | int | `3` | Failure threshold for readiness probe |
| readinessProbe.spec.httpGet | object | `{"path":"/readyz","port":8081}` | HTTP GET configuration |
| readinessProbe.spec.httpGet.path | string | `"/readyz"` | Readiness probe path |
| readinessProbe.spec.httpGet.port | int | `8081` | Readiness probe port |
| readinessProbe.spec.initialDelaySeconds | int | `20` | Initial delay before readiness probe |
| readinessProbe.spec.periodSeconds | int | `10` | Period between readiness probes |
| readinessProbe.spec.timeoutSeconds | int | `5` | Timeout for readiness probe |
| resources.limits | object | `{"cpu":"1000m","memory":"1Gi"}` | Resource limits |
| resources.limits.cpu | string | `"1000m"` | CPU limit |
| resources.limits.memory | string | `"1Gi"` | Memory limit |
| resources.requests | object | `{"cpu":"250m","memory":"256Mi"}` | Resource requests |
| resources.requests.cpu | string | `"250m"` | CPU request |
| resources.requests.memory | string | `"256Mi"` | Memory request |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.name | string | `"external-secrets"` | Service account name |
| serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| serviceMonitor.honorLabels | bool | `true` | Honor labels from service |
| serviceMonitor.interval | string | `"60s"` | Scrape interval |
| serviceMonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| webhook.certManager | object | `{"addInjectorAnnotations":true,"cert":{"create":true,"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"ClusterIssuer","name":"ca-issuer"},"privateKey":{"rotationPolicy":"Always"},"renewBefore":"720h"},"enabled":true}` | Cert-manager integration |
| webhook.certManager.addInjectorAnnotations | bool | `true` | Automatically inject CA into webhooks and CRDs |
| webhook.certManager.cert | object | `{"create":true,"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"ClusterIssuer","name":"ca-issuer"},"privateKey":{"rotationPolicy":"Always"},"renewBefore":"720h"}` | Certificate configuration |
| webhook.certManager.cert.create | bool | `true` | Create certificate resource |
| webhook.certManager.cert.duration | string | `"2160h"` | Certificate lifetime (90 days) |
| webhook.certManager.cert.issuerRef | object | `{"group":"cert-manager.io","kind":"ClusterIssuer","name":"ca-issuer"}` | Certificate issuer reference |
| webhook.certManager.cert.issuerRef.group | string | `"cert-manager.io"` | Issuer group |
| webhook.certManager.cert.issuerRef.kind | string | `"ClusterIssuer"` | Issuer kind |
| webhook.certManager.cert.issuerRef.name | string | `"ca-issuer"` | Issuer name |
| webhook.certManager.cert.privateKey | object | `{"rotationPolicy":"Always"}` | Private key configuration |
| webhook.certManager.cert.privateKey.rotationPolicy | string | `"Always"` | Private key rotation policy |
| webhook.certManager.cert.renewBefore | string | `"720h"` | Renew certificate 30 days before expiry |
| webhook.certManager.enabled | bool | `true` | Enable cert-manager for webhook certificates |
| webhook.lookaheadInterval | string | `"168h"` | Certificate validity lookahead interval (must be less than cert.renewBefore) |