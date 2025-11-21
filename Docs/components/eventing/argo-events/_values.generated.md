# argo-events

![Version: 2.4.12](https://img.shields.io/badge/Version-2.4.12-informational?style=flat-square)

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `2.4.12` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.affinity | object | `{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists"}]}]}}}` | Node affinity for controller (schedule on control-plane for stability) |
| controller.deploymentStrategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Rolling update strategy for zero-downtime updates |
| controller.deploymentStrategy.rollingUpdate.maxSurge | int | `1` | Maximum surge pods during update |
| controller.deploymentStrategy.rollingUpdate.maxUnavailable | int | `0` | Maximum unavailable pods during update (0 for zero-downtime) |
| controller.metrics | object | `{"enabled":true,"path":"/metrics","port":7777,"serviceMonitor":{"additionalLabels":{"prometheus":"kube-prometheus"},"enabled":true}}` | Metrics configuration for the controller |
| controller.metrics.enabled | bool | `true` | Enable Prometheus metrics endpoint |
| controller.metrics.path | string | `"/metrics"` | Path for metrics endpoint |
| controller.metrics.port | int | `7777` | Port for metrics endpoint |
| controller.metrics.serviceMonitor.additionalLabels | object | `{"prometheus":"kube-prometheus"}` | Additional labels for ServiceMonitor |
| controller.metrics.serviceMonitor.additionalLabels.prometheus | string | `"kube-prometheus"` | Prometheus selector label |
| controller.metrics.serviceMonitor.enabled | bool | `true` | Create ServiceMonitor for controller metrics |
| controller.priorityClassName | string | `"platform-events"` | Priority class for controller pods |
| controller.replicas | int | `1` | Number of controller replicas |
| controller.resources | object | `{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the controller |
| controller.resources.limits.cpu | string | `"200m"` | CPU limit for the controller |
| controller.resources.limits.memory | string | `"256Mi"` | Memory limit for the controller |
| controller.resources.requests.cpu | string | `"50m"` | CPU request for the controller |
| controller.resources.requests.memory | string | `"64Mi"` | Memory request for the controller |
| controller.tolerations | list | `[{"effect":"NoSchedule","key":"node-role.kubernetes.io/control-plane","operator":"Exists"}]` | Tolerations for controller to run on control-plane node |
| crds.install | bool | `true` | Install Argo Events CRDs |
| crds.keep | bool | `true` | Keep CRDs on chart uninstall |
| global.image | object | `{"pullPolicy":"IfNotPresent"}` | Image pull policy for all components |
| webhook.affinity | object | `{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists"}]}]}}}` | Node affinity for webhook (schedule on control-plane for stability) |
| webhook.enabled | bool | `true` | Enable the validating admission webhook |
| webhook.priorityClassName | string | `"platform-events"` | Priority class for webhook pods |
| webhook.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"25m","memory":"32Mi"}}` | Resource requests and limits for the webhook |
| webhook.resources.limits.cpu | string | `"100m"` | CPU limit for the webhook |
| webhook.resources.limits.memory | string | `"128Mi"` | Memory limit for the webhook |
| webhook.resources.requests.cpu | string | `"25m"` | CPU request for the webhook |
| webhook.resources.requests.memory | string | `"32Mi"` | Memory request for the webhook |
| webhook.tolerations | list | `[{"effect":"NoSchedule","key":"node-role.kubernetes.io/control-plane","operator":"Exists"}]` | Tolerations for webhook to run on control-plane node |
