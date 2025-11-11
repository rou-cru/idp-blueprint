# kyverno

This document lists the configuration parameters for the `kyverno` component.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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