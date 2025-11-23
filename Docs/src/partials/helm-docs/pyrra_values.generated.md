# pyrra

![Version: 0.19.2](https://img.shields.io/badge/Version-0.19.2-informational?style=flat-square) 

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.19.2` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| priorityClassName | string | `"platform-observability"` | Priority class for Pyrra pods |
| resources.limits.cpu | string | `"200m"` | CPU limit |
| resources.limits.memory | string | `"256Mi"` | Memory limit |
| resources.requests.cpu | string | `"50m"` | CPU request |
| resources.requests.memory | string | `"64Mi"` | Memory request |
| serviceMonitor | object | `{"additionalLabels":{"prometheus":"kube-prometheus"},"enabled":true}` | Create a ServiceMonitor for Prometheus Operator |
| serviceMonitor.additionalLabels.prometheus | string | `"kube-prometheus"` | Prometheus selector label |
| serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor for Pyrra |

