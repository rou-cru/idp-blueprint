# kyverno

This document lists the configuration parameters for the `kyverno` component.

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
| readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Readiness probe for the main admission controller. |
| reportsController.resources.limits.cpu | string | `"250m"` |  |
| reportsController.resources.limits.memory | string | `"256Mi"` |  |
| reportsController.resources.requests.cpu | string | `"100m"` |  |
| reportsController.resources.requests.memory | string | `"128Mi"` |  |
| resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resources for the main admission controller. |
| startupProbe | object | `{"failureThreshold":30,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Startup probe for the main admission controller. |