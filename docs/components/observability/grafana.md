# grafana

![Version: latest](https://img.shields.io/badge/Version-latest-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://grafana.com/grafana/)

The leading platform for analytics and monitoring

## Component Information

| Property | Value |
|----------|-------|
| **Chart Type** | `application` |
| **Upstream Project** | [grafana](https://grafana.com/grafana/) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Configuration Values

The following table lists the configurable parameters from the Prometheus chart that includes Grafana:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
| grafana.sidecar | object | `{"dashboards":{"enabled":true,"label":"grafana_dashboard","labelValue":""}}` | Sidecard to automatically discover and load dashboards from ConfigMaps. |
| grafana.sidecar.dashboards.labelValue | string | `""` | An empty labelValue searches for the presence of the label, regardless of its value. |