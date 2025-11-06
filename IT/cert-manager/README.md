# cert-manager

This document lists the configuration parameters for the `cert-manager` component.

## Values

### CA Injector

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cainjector | object | `{"resources":{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | CA injector configuration |

### Custom Resource Definitions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds | object | `{"enabled":true}` | CRD installation configuration |

### General Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| priorityClassName | string | `"platform-infrastructure"` | Priority class for cert-manager pods |

### Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus | object | `{"enabled":true,"servicemonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}}` | Prometheus metrics configuration |

### Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}` | Resource requests and limits for cert-manager |

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