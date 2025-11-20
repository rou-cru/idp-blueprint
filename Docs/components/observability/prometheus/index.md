# prometheus

![Version: 77.14.0](https://img.shields.io/badge/Version-77.14.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://prometheus.io)

Prometheus monitoring stack with Grafana and Alertmanager

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `77.14.0` |
| **Chart Type** | `application` |
| **Upstream Project** | [prometheus](https://prometheus.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Prometheus?

Prometheus uses a pull model: it scrapes metrics from targets on a schedule. This provides precise control over cardinality and scrape intervals, which helps prevent metric explosions in resource-constrained environments.

The kube-prometheus-stack Helm chart bundles Prometheus with Grafana, Alertmanager, and pre-configured dashboards for Kubernetes components. This reduces the initial configuration work.

ServiceMonitor CRDs make metrics collection declarative. Instead of manually editing Prometheus config files, you define ServiceMonitor resources and Prometheus discovers them automatically, which fits the GitOps approach.

## Architecture Role

Prometheus operates at **Layer 1** of the platform, the Platform Services layer. It's a transversal service that monitors everything above it.

Key integration points:

- **ServiceMonitors**: Declared by components (Cilium, ArgoCD, Kyverno, etc.) to expose metrics
- **Grafana**: Queries Prometheus for metrics visualization
- **Pyrra**: Uses Prometheus metrics to calculate SLO burn rates
- **Alertmanager**: Receives alerts from Prometheus evaluation rules (currently enabled for Pyrra support)

The configuration uses a pull model with ServiceMonitor CRDs for discovery. Scrape intervals are tuned per target (e.g., 30s for CNI metrics, 60s for application metrics). This balances visibility with resource efficiency.

Prometheus doesn't currently drive any HorizontalPodAutoscalers (HPAs), meaning metrics are used for passive observability rather than active scaling. This is an opportunity for future optimization.

See [Observability Model](../../../architecture/observability.md) for the complete observability architecture.

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alertmanager.enabled | bool | `false` | Disabled by default. This blueprint uses Grafana Unified Alerting as the primary platform for managing alerts from all datasources (Prometheus, Loki, etc.), providing a single, integrated user experience. |
| crds | object | `{"enabled":false}` | Disables the installation of CRDs, as they are managed separately. |
| grafana."grafana.ini" | object | `{"users":{"allow_sign_up":false,"default_theme":"dark"}}` | Advanced Grafana configuration via grafana.ini |
| grafana."grafana.ini".users.allow_sign_up | bool | `false` | Disables the user sign-up page. |
| grafana."grafana.ini".users.default_theme | string | `"dark"` | Set the default UI theme to dark. |
| grafana.additionalDataSources | list | `[{"access":"proxy","isDefault":false,"name":"Loki","type":"loki","url":"http://loki.observability.svc.cluster.local:3100"}]` | Additional datasources for Grafana. |
| grafana.admin | object | `{"existingSecret":"grafana-admin-credentials","passwordKey":"admin-password","userKey":"admin-user"}` | Use existing secret for admin credentials from Vault via ESO. |
| grafana.persistence | object | `{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"1Gi","type":"pvc"}` | Enable persistence for dashboards and settings |
| grafana.plugins | list | `["grafana-piechart-panel","grafana-polystat-panel","marcusolsson-json-datasource"]` | Automatically install useful plugins on startup. |
| grafana.priorityClassName | string | `"platform-dashboards"` |  |
| grafana.resources.limits.cpu | string | `"250m"` | CPU limit |
| grafana.resources.limits.memory | string | `"256Mi"` | Memory limit |
| grafana.resources.requests.cpu | string | `"50m"` | CPU request |
| grafana.resources.requests.memory | string | `"128Mi"` | Memory request |
| grafana.sidecar | object | `{"dashboards":{"enabled":true,"label":"grafana_dashboard","labelValue":""}}` | Sidecar to automatically discover and load dashboards from ConfigMaps. |
| grafana.sidecar.dashboards.labelValue | string | `""` | An empty labelValue searches for the presence of the label, regardless of its value. |
| kube-state-metrics | object | `{"extraArgs":["--resources=cronjobs,daemonsets,deployments,jobs,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,pods,services,statefulsets,storageclasses"],"priorityClassName":"platform-observability","prometheus":{"monitor":{"metricRelabelings":[{"action":"labeldrop","regex":"uid"},{"action":"labeldrop","regex":"container_id"},{"action":"labeldrop","regex":"image_id"}]}},"resources":{"limits":{"cpu":"50m","memory":"128Mi"},"requests":{"cpu":"25m","memory":"64Mi"}}}` | Resource limits and requests for kube-state-metrics. |
| kube-state-metrics.extraArgs | list | `["--resources=cronjobs,daemonsets,deployments,jobs,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,pods,services,statefulsets,storageclasses"]` | Enable only relevant resource types (whitelist approach) |
| kube-state-metrics.priorityClassName | string | `"platform-observability"` | Priority class |
| kube-state-metrics.prometheus.monitor.metricRelabelings | list | `[{"action":"labeldrop","regex":"uid"},{"action":"labeldrop","regex":"container_id"},{"action":"labeldrop","regex":"image_id"}]` | Drop high-cardinality labels |
| kube-state-metrics.resources.limits.cpu | string | `"50m"` | CPU limit |
| kube-state-metrics.resources.limits.memory | string | `"128Mi"` | Memory limit |
| kube-state-metrics.resources.requests.cpu | string | `"25m"` | CPU request |
| kube-state-metrics.resources.requests.memory | string | `"64Mi"` | Memory request |
| prometheus-node-exporter | object | `{"extraArgs":["--collector.disable-defaults","--collector.cpu","--collector.cpufreq","--collector.meminfo","--collector.diskstats","--collector.filesystem","--collector.netdev","--collector.loadavg","--collector.pressure","--collector.vmstat","--collector.stat","--collector.uname"],"priorityClassName":"platform-observability","resources":{"limits":{"cpu":"30m","memory":"48Mi"},"requests":{"cpu":"15m","memory":"24Mi"}}}` | Resource limits and requests for the node-exporter. |
| prometheus-node-exporter.extraArgs | list | `["--collector.disable-defaults","--collector.cpu","--collector.cpufreq","--collector.meminfo","--collector.diskstats","--collector.filesystem","--collector.netdev","--collector.loadavg","--collector.pressure","--collector.vmstat","--collector.stat","--collector.uname"]` | Minimal collector set optimized for K3d |
| prometheus-node-exporter.priorityClassName | string | `"platform-observability"` | Priority class |
| prometheus-node-exporter.resources.limits.cpu | string | `"30m"` | CPU limit |
| prometheus-node-exporter.resources.limits.memory | string | `"48Mi"` | Memory limit |
| prometheus-node-exporter.resources.requests.cpu | string | `"15m"` | CPU request |
| prometheus-node-exporter.resources.requests.memory | string | `"24Mi"` | Memory request |
| prometheus.priorityClassName | string | `"platform-observability"` |  |
| prometheus.prometheusSpec.resources.limits.cpu | string | `"250m"` | CPU limit |
| prometheus.prometheusSpec.resources.limits.memory | string | `"512Mi"` | Memory limit |
| prometheus.prometheusSpec.resources.requests.cpu | string | `"100m"` | CPU request |
| prometheus.prometheusSpec.resources.requests.memory | string | `"384Mi"` | Memory request |
| prometheus.prometheusSpec.retention | string | `"6h"` | Metrics retention time. |
| prometheus.prometheusSpec.scrapeInterval | string | `"60s"` | Global scrape interval for all ServiceMonitors (unless overridden). |
| prometheus.prometheusSpec.scrapeTimeout | string | `"40s"` | Global scrape timeout for all ServiceMonitors (unless overridden). |
| prometheus.prometheusSpec.storageSpec | object | `{"volumeClaimTemplate":{"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"1Gi"}}}}}` | Enable persistence for Prometheus TSDB. 1Gi supports 6h retention for ~50 pods with 4x overhead margin. Data survives pod restarts but is lost on cluster destruction. |
| prometheusOperator | object | `{"priorityClassName":"platform-observability","resources":{"limits":{"cpu":"50m","memory":"64Mi"},"requests":{"cpu":"25m","memory":"32Mi"}}}` | Resource limits and requests for the Prometheus Operator. |
| prometheusOperator.priorityClassName | string | `"platform-observability"` | Priority class |
| prometheusOperator.resources.limits.cpu | string | `"50m"` | CPU limit |
| prometheusOperator.resources.limits.memory | string | `"64Mi"` | Memory limit |
| prometheusOperator.resources.requests.cpu | string | `"25m"` | CPU request |
| prometheusOperator.resources.requests.memory | string | `"32Mi"` | Memory request |
| windows-exporter | object | `{"enabled":false}` | Disables unnecessary components. |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
