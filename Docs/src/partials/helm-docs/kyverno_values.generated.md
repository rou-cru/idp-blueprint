# kyverno

![Version: 3.5.2](https://img.shields.io/badge/Version-3.5.2-informational?style=flat-square)

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `3.5.2` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

### Deployment Strategy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admissionController | object | `{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}}` | Rolling update strategy for zero-downtime updates |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admissionController.strategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Deployment strategy for admission controller |
| admissionController.strategy.rollingUpdate.maxSurge | int | `1` | Maximum surge pods during update |
| admissionController.strategy.rollingUpdate.maxUnavailable | int | `0` | Maximum unavailable pods during update (0 for zero-downtime) |
| backgroundController.resources.limits.cpu | string | `"250m"` | CPU limit for background controller |
| backgroundController.resources.limits.memory | string | `"256Mi"` | Memory limit for background controller |
| backgroundController.resources.requests.cpu | string | `"100m"` | CPU request for background controller |
| backgroundController.resources.requests.memory | string | `"128Mi"` | Memory request for background controller |
| cleanupController.resources.limits.cpu | string | `"250m"` | CPU limit for cleanup controller |
| cleanupController.resources.limits.memory | string | `"256Mi"` | Memory limit for cleanup controller |
| cleanupController.resources.requests.cpu | string | `"100m"` | CPU request for cleanup controller |
| cleanupController.resources.requests.memory | string | `"128Mi"` | Memory request for cleanup controller |
| crds.install | bool | `true` | Install Kyverno CRDs |
| livenessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probe for the main admission controller. |
| livenessProbe.failureThreshold | int | `3` | Failed probes tolerated before restart |
| livenessProbe.initialDelaySeconds | int | `0` | Delay before starting liveness checks |
| livenessProbe.periodSeconds | int | `10` | Frequency of liveness probes |
| livenessProbe.successThreshold | int | `1` | Successful probes required to mark ready |
| livenessProbe.timeoutSeconds | int | `1` | Timeout per liveness probe |
| priorityClassName | string | `"platform-policy"` | Priority class for Kyverno admission controller |
| readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Readiness probe for the main admission controller. |
| readinessProbe.failureThreshold | int | `3` | Failed readiness probes tolerated |
| readinessProbe.initialDelaySeconds | int | `0` | Delay before starting readiness checks |
| readinessProbe.periodSeconds | int | `10` | Frequency of readiness probes |
| readinessProbe.successThreshold | int | `1` | Successful probes required to be ready |
| readinessProbe.timeoutSeconds | int | `1` | Timeout per readiness probe |
| reportsController.resources.limits.cpu | string | `"250m"` | CPU limit for reports controller |
| reportsController.resources.limits.memory | string | `"256Mi"` | Memory limit for reports controller |
| reportsController.resources.requests.cpu | string | `"100m"` | CPU request for reports controller |
| reportsController.resources.requests.memory | string | `"128Mi"` | Memory request for reports controller |
| resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resources for the main admission controller. |
| resources.limits.cpu | string | `"250m"` | CPU limit for admission controller |
| resources.limits.memory | string | `"256Mi"` | Memory limit for admission controller |
| resources.requests.cpu | string | `"100m"` | CPU request for admission controller |
| resources.requests.memory | string | `"128Mi"` | Memory request for admission controller |
| startupProbe | object | `{"failureThreshold":30,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Startup probe for the main admission controller. |
| startupProbe.failureThreshold | int | `30` | Failed startup probes tolerated |
| startupProbe.initialDelaySeconds | int | `0` | Delay before starting startup probes |
| startupProbe.periodSeconds | int | `10` | Frequency of startup probes |
| startupProbe.successThreshold | int | `1` | Successful startup probes required |
| startupProbe.timeoutSeconds | int | `1` | Timeout per startup probe |
