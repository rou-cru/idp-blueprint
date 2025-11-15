# cert-manager

![Version: latest](https://img.shields.io/badge/Version-latest-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://cert-manager.io)

Cloud-native certificate management for Kubernetes

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `latest` |
| **Chart Type** | `application` |
| **Upstream Project** | [cert-manager](https://cert-manager.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Cert-Manager?

Cert-Manager automates TLS certificate issuance and renewal. The alternative is manual certificate generation, distribution, tracking expiration dates, and renewal.

It supports multiple certificate authorities (Let's Encrypt, Venafi, self-signed, enterprise CAs) and challenge types (HTTP-01, DNS-01, TLS-ALPN-01). For this platform, it bootstraps a self-signed CA and uses it to issue certificates for internal services.

Certificates auto-renew before expiration. Services reference certificates via Kubernetes Secrets, which Cert-Manager updates. When mTLS is added in the future, Cert-Manager can issue per-pod certificates and rotate them automatically.

Cert-Manager doesn't depend on provider-specific certificate services, keeping the platform portable.

## Architecture Role

Cert-Manager operates at **Layer 1** of the platform, the Platform Services layer. It's a cross-cutting service that provides PKI for any component that needs TLS.

Key integration points:

- **ClusterIssuers**: Define certificate authorities (self-signed, CA-based, ACME)
- **Certificates**: Declarative resources that request certificates from issuers
- **Kubernetes Secrets**: Cert-Manager stores certificates here, making them consumable by any workload
- **Gateway API**: Uses the `idp-wildcard-cert` certificate for TLS termination

The PKI bootstrap process is fully declarative:

1. Self-signed ClusterIssuer creates a root CA certificate
2. That CA certificate backs a CA ClusterIssuer
3. The CA ClusterIssuer issues certificates for applications

This pattern creates a complete, self-contained PKI without external dependencies.

See [Architecture Overview](../../../architecture/overview.md#2-public-key-infrastructure-pki) for the PKI flow diagram.

## Configuration Values

The following table lists the configurable parameters:

## Values

### CA Injector

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cainjector | object | `{"resources":{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | CA injector configuration |

### Custom Resource Definitions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds | object | `{"enabled":true}` | CRD installation configuration |

### Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus | object | `{"enabled":true,"servicemonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}}` | Prometheus metrics configuration |

### Webhook

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| webhook | object | `{"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/livez","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"resources":{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Webhook configuration |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cainjector.resources | object | `{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource settings for cainjector |
| cainjector.resources.limits | object | `{"cpu":"200m","memory":"256Mi"}` | Resource limits |
| cainjector.resources.limits.cpu | string | `"200m"` | CPU limit |
| cainjector.resources.limits.memory | string | `"256Mi"` | Memory limit |
| cainjector.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Resource requests |
| cainjector.resources.requests.cpu | string | `"100m"` | CPU request |
| cainjector.resources.requests.memory | string | `"128Mi"` | Memory request |
| crds.enabled | bool | `true` | Enable the installation of cert-manager CRDs |
| global.priorityClassName | string | `"platform-infrastructure"` |  |
| prometheus.enabled | bool | `true` | Enable Prometheus metrics |
| prometheus.servicemonitor | object | `{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}` | ServiceMonitor configuration |
| prometheus.servicemonitor.enabled | bool | `true` | Enable ServiceMonitor for cert-manager components |
| prometheus.servicemonitor.interval | string | `"60s"` | Scrape interval |
| prometheus.servicemonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| resources.limits | object | `{"cpu":"500m","memory":"512Mi"}` | Resource limits |
| resources.limits.cpu | string | `"500m"` | CPU limit |
| resources.limits.memory | string | `"512Mi"` | Memory limit |
| resources.requests | object | `{"cpu":"250m","memory":"256Mi"}` | Resource requests |
| resources.requests.cpu | string | `"250m"` | CPU request |
| resources.requests.memory | string | `"256Mi"` | Memory request |
| webhook.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/livez","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probe for the webhook pod |
| webhook.livenessProbe.failureThreshold | int | `3` | Failure threshold for liveness probe |
| webhook.livenessProbe.httpGet | object | `{"path":"/livez","port":6080,"scheme":"HTTP"}` | HTTP GET configuration |
| webhook.livenessProbe.httpGet.path | string | `"/livez"` | Liveness probe path |
| webhook.livenessProbe.httpGet.port | int | `6080` | Liveness probe port |
| webhook.livenessProbe.httpGet.scheme | string | `"HTTP"` | Liveness probe scheme |
| webhook.livenessProbe.initialDelaySeconds | int | `0` | Initial delay before liveness probe |
| webhook.livenessProbe.periodSeconds | int | `10` | Period between liveness probes |
| webhook.livenessProbe.successThreshold | int | `1` | Success threshold for liveness probe |
| webhook.livenessProbe.timeoutSeconds | int | `1` | Timeout for liveness probe |
| webhook.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/healthz","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Readiness probe for the webhook pod |
| webhook.readinessProbe.failureThreshold | int | `3` | Failure threshold for readiness probe |
| webhook.readinessProbe.httpGet | object | `{"path":"/healthz","port":6080,"scheme":"HTTP"}` | HTTP GET configuration |
| webhook.readinessProbe.httpGet.path | string | `"/healthz"` | Readiness probe path |
| webhook.readinessProbe.httpGet.port | int | `6080` | Readiness probe port |
| webhook.readinessProbe.httpGet.scheme | string | `"HTTP"` | Readiness probe scheme |
| webhook.readinessProbe.initialDelaySeconds | int | `0` | Initial delay before readiness probe |
| webhook.readinessProbe.periodSeconds | int | `10` | Period between readiness probes |
| webhook.readinessProbe.successThreshold | int | `1` | Success threshold for readiness probe |
| webhook.readinessProbe.timeoutSeconds | int | `1` | Timeout for readiness probe |
| webhook.resources | object | `{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource settings for the webhook |
| webhook.resources.limits | object | `{"cpu":"200m","memory":"256Mi"}` | Resource limits |
| webhook.resources.limits.cpu | string | `"200m"` | CPU limit |
| webhook.resources.limits.memory | string | `"256Mi"` | Memory limit |
| webhook.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Resource requests |
| webhook.resources.requests.cpu | string | `"100m"` | CPU request |
| webhook.resources.requests.memory | string | `"128Mi"` | Memory request |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
