# policy-reporter

![Version: 3.5.0](https://img.shields.io/badge/Version-3.5.0-informational?style=flat-square) 

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `3.5.0` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| policyReporter.resources | object | `{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the core engine. |
| policyReporter.resources.limits.cpu | string | `"200m"` | CPU limit for Policy Reporter |
| policyReporter.resources.limits.memory | string | `"128Mi"` | Memory limit for Policy Reporter |
| policyReporter.resources.requests.cpu | string | `"50m"` | CPU request for Policy Reporter |
| policyReporter.resources.requests.memory | string | `"64Mi"` | Memory request for Policy Reporter |
| priorityClassName | string | `"platform-observability"` | Priority class for Policy Reporter |
| ui.enabled | bool | `true` | Enables the deployment of the Policy Reporter UI. |
| ui.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the UI. |
| ui.resources.limits.cpu | string | `"100m"` | CPU limit for the UI |
| ui.resources.limits.memory | string | `"128Mi"` | Memory limit for the UI |
| ui.resources.requests.cpu | string | `"50m"` | CPU request for the UI |
| ui.resources.requests.memory | string | `"64Mi"` | Memory request for the UI |

