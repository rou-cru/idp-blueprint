# cert-manager

![Version: v1.19.0](https://img.shields.io/badge/Version-v1.19.0-informational?style=flat-square) 

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `v1.19.0` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

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

### Deployment Strategy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| strategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Rolling update strategy for zero-downtime updates |

### Webhook

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| webhook | object | `{"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/livez","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/healthz","port":6080,"scheme":"HTTP"},"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"resources":{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Webhook configuration |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"node-role.kubernetes.io/control-plane"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"Exists"` |  |
| cainjector.resources.limits.cpu | string | `"200m"` | CPU limit |
| cainjector.resources.limits.memory | string | `"256Mi"` | Memory limit |
| cainjector.resources.requests.cpu | string | `"100m"` | CPU request |
| cainjector.resources.requests.memory | string | `"128Mi"` | Memory request |
| crds.enabled | bool | `true` | Enable the installation of cert-manager CRDs |
| global.priorityClassName | string | `"platform-infrastructure"` |  |
| prometheus.enabled | bool | `true` | Enable Prometheus metrics |
| prometheus.servicemonitor | object | `{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}` | ServiceMonitor configuration |
| prometheus.servicemonitor.enabled | bool | `true` | Enable ServiceMonitor for cert-manager components |
| prometheus.servicemonitor.interval | string | `"60s"` | Scrape interval |
| prometheus.servicemonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| resources.limits.cpu | string | `"500m"` | CPU limit |
| resources.limits.memory | string | `"512Mi"` | Memory limit |
| resources.requests.cpu | string | `"250m"` | CPU request |
| resources.requests.memory | string | `"256Mi"` | Memory request |
| strategy.rollingUpdate.maxSurge | int | `1` | Maximum surge pods during update |
| strategy.rollingUpdate.maxUnavailable | int | `0` | Maximum unavailable pods during update (0 for zero-downtime) |
| tolerations[0].effect | string | `"NoSchedule"` |  |
| tolerations[0].key | string | `"node-role.kubernetes.io/control-plane"` |  |
| tolerations[0].operator | string | `"Exists"` |  |
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
| webhook.resources.limits.cpu | string | `"200m"` | CPU limit |
| webhook.resources.limits.memory | string | `"256Mi"` | Memory limit |
| webhook.resources.requests.cpu | string | `"100m"` | CPU request |
| webhook.resources.requests.memory | string | `"128Mi"` | Memory request |

