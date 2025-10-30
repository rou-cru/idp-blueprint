# kube-prometheus-stack

This document lists the configuration parameters for the `kube-prometheus-stack` component.

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
| grafana.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resource limits and requests for Grafana. |
| grafana.sidecar | object | `{"dashboards":{"enabled":true,"label":"grafana_dashboard","labelValue":""}}` | Sidecar to automatically discover and load dashboards from ConfigMaps. |
| grafana.sidecar.dashboards.labelValue | string | `""` | An empty labelValue searches for the presence of the label, regardless of its value. |
| kube-state-metrics | object | `{"extraArgs":["--resources=cronjobs,daemonsets,deployments,jobs,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,pods,services,statefulsets,storageclasses"],"priorityClassName":"platform-observability","prometheus":{"monitor":{"metricRelabelings":[{"action":"labeldrop","regex":"uid"},{"action":"labeldrop","regex":"container_id"},{"action":"labeldrop","regex":"image_id"}]}},"resources":{"limits":{"cpu":"50m","memory":"128Mi"},"requests":{"cpu":"25m","memory":"64Mi"}}}` | Resource limits and requests for kube-state-metrics. |
| kube-state-metrics.extraArgs | list | `["--resources=cronjobs,daemonsets,deployments,jobs,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,pods,services,statefulsets,storageclasses"]` | Enable only relevant resource types (whitelist approach). Disables: ReplicaSets, ConfigMaps, Secrets, RBAC, HPAs, Leases, Webhooks, etc. |
| kube-state-metrics.prometheus.monitor.metricRelabelings | list | `[{"action":"labeldrop","regex":"uid"},{"action":"labeldrop","regex":"container_id"},{"action":"labeldrop","regex":"image_id"}]` | Drop high-cardinality labels that add noise without operational value. |
| kube-state-metrics.prometheus.monitor.metricRelabelings[0] | object | `{"action":"labeldrop","regex":"uid"}` | Drop uid label: UUIDs not useful in dashboards/queries |
| kube-state-metrics.prometheus.monitor.metricRelabelings[1] | object | `{"action":"labeldrop","regex":"container_id"}` | Drop container_id: SHA256 hashes change on every restart (high churn) |
| kube-state-metrics.prometheus.monitor.metricRelabelings[2] | object | `{"action":"labeldrop","regex":"image_id"}` | Drop image_id: SHA256 hashes redundant with image tag |
| prometheus-node-exporter | object | `{"extraArgs":["--collector.disable-defaults","--collector.cpu","--collector.cpufreq","--collector.meminfo","--collector.diskstats","--collector.filesystem","--collector.netdev","--collector.loadavg","--collector.pressure","--collector.vmstat","--collector.stat","--collector.uname"],"priorityClassName":"platform-observability","resources":{"limits":{"cpu":"30m","memory":"48Mi"},"requests":{"cpu":"15m","memory":"24Mi"}}}` | Resource limits and requests for the node-exporter. |
| prometheus-node-exporter.extraArgs | list | `["--collector.disable-defaults","--collector.cpu","--collector.cpufreq","--collector.meminfo","--collector.diskstats","--collector.filesystem","--collector.netdev","--collector.loadavg","--collector.pressure","--collector.vmstat","--collector.stat","--collector.uname"]` | Minimal collector set optimized for K3d + Cilium eBPF environments. Uses whitelist approach (disable defaults, enable only essentials) to minimize overhead. |
| prometheus-node-exporter.extraArgs[0] | string | `"--collector.disable-defaults"` | Disable all default collectors (40+ collectors) |
| prometheus-node-exporter.extraArgs[1] | string | `"--collector.cpu"` | Enable ONLY essential collectors for K8s observability (10 collectors) |
| prometheus.priorityClassName | string | `"platform-observability"` |  |
| prometheus.prometheusSpec.resources | object | `{"limits":{"cpu":"250m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"384Mi"}}` | Resource limits and requests for Prometheus. |
| prometheus.prometheusSpec.retention | string | `"6h"` | Metrics retention time. |
| prometheus.prometheusSpec.scrapeInterval | string | `"60s"` | Global scrape interval for all ServiceMonitors (unless overridden). |
| prometheus.prometheusSpec.scrapeTimeout | string | `"40s"` | Global scrape timeout for all ServiceMonitors (unless overridden). |
| prometheus.prometheusSpec.storageSpec | object | `{"volumeClaimTemplate":{"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"1Gi"}}}}}` | Enable persistence for Prometheus TSDB. 1Gi supports 6h retention for ~50 pods with 4x overhead margin. Data survives pod restarts but is lost on cluster destruction. |
| prometheusOperator | object | `{"priorityClassName":"platform-observability","resources":{"limits":{"cpu":"50m","memory":"64Mi"},"requests":{"cpu":"25m","memory":"32Mi"}}}` | Resource limits and requests for the Prometheus Operator. |
| windows-exporter | object | `{"enabled":false}` | Disables unnecessary components. |