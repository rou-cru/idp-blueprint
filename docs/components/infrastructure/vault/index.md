# vault

![Version: 0.31.0](https://img.shields.io/badge/Version-0.31.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://www.vaultproject.io)

Secrets management and data protection platform

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.31.0` |
| **Chart Type** | `application` |
| **Upstream Project** | [vault](https://www.vaultproject.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.dataStorage.enabled | bool | `true` | Enable persistence |
| server.dataStorage.size | string | `"1Gi"` | Storage size |
| server.livenessProbe.enabled | bool | `false` | Enable liveness probe |
| server.livenessProbe.execCommand | list | `[]` | Exec command |
| server.livenessProbe.failureThreshold | int | `2` | Failure threshold |
| server.livenessProbe.initialDelaySeconds | int | `5` | Initial delay seconds |
| server.livenessProbe.periodSeconds | int | `2` | Period seconds |
| server.livenessProbe.successThreshold | int | `1` | Success threshold |
| server.livenessProbe.timeoutSeconds | int | `5` | Timeout seconds |
| server.priorityClassName | string | `"platform-infrastructure"` | Priority class for Vault pods |
| server.readinessProbe.enabled | bool | `true` | Enable readiness probe |
| server.readinessProbe.failureThreshold | int | `2` | Failure threshold |
| server.readinessProbe.initialDelaySeconds | int | `5` | Initial delay seconds |
| server.readinessProbe.path | string | `"/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"` | Readiness probe path |
| server.resources.limits.cpu | string | `"500m"` | CPU limit |
| server.resources.limits.memory | string | `"512Mi"` | Memory limit |
| server.resources.requests.cpu | string | `"250m"` | CPU request |
| server.resources.requests.memory | string | `"256Mi"` | Memory request |
| server.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| server.serviceMonitor.interval | string | `"60s"` | Scrape interval |
| server.serviceMonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| server.standalone.config | string | `"storage \"raft\" {\n  path    = \"/vault/data\"\n  node_id = \"vault-0\"\n}\nlistener \"tcp\" {\n  address         = \"0.0.0.0:8200\"\n  tls_disable     = \"true\"\n  telemetry {\n    unauthenticated_metrics_access = true\n  }\n}\ntelemetry {\n  prometheus_retention_time = \"30s\"\n  disable_hostname          = true\n}\naudit \"file\" {\n  path = \"/vault/logs/audit.log\"\n}\n"` | HCL configuration for the Raft storage backend |
| server.standalone.enabled | bool | `true` | Enables standalone server configuration |
| ui.enabled | bool | `true` | Enable Vault UI |
| ui.service.type | string | `"ClusterIP"` | Service type |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
