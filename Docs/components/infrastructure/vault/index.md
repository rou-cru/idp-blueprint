# vault

![Version: latest](https://img.shields.io/badge/Version-latest-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://www.vaultproject.io)

Secrets management and data protection platform

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `latest` |
| **Chart Type** | `application` |
| **Upstream Project** | [vault](https://www.vaultproject.io) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Vault?

Vault is the secrets backend for this platform, and the choice is about portability and security. Using cloud provider secret managers would create vendor lock-in, require users to register with that specific provider, and force the platform to handle the nuances of each provider's API. Vault eliminates all of that.

Vault is portable. It runs anywhere Kubernetes runs. It's secure when configured correctly. And it enables 100% automated deployments without relying on hardcoded values or insecure practices. Users can still extend the platform to connect Vault to their preferred cloud provider's secret manager if needed, but Vault provides a consistent interface regardless of where secrets ultimately come from.

The key benefits:

- **No Vendor Lock-In**: Vault works the same on AWS, GCP, Azure, or bare metal
- **Centralized Management**: Single source of truth for all secrets across the platform
- **Automated Rotation**: Supports dynamic secrets and automatic rotation
- **Audit Trail**: Every secret access is logged
- **Developer-Friendly**: Applications consume standard Kubernetes Secrets, not Vault's API directly

## Architecture Role

Vault sits at **Layer 1** of the platform, the Platform Services layer. It's a cross-cutting service that nearly every component depends on for credentials.

Key integration points:

- **External Secrets Operator**: Syncs secrets from Vault into Kubernetes Secrets
- **ArgoCD**: Consumes Vault secrets for repository credentials
- **Grafana**: Uses Vault-sourced secrets for admin passwords and datasource credentials
- **Applications**: Consume secrets via standard Kubernetes Secrets, decoupled from Vault's API

The configuration here uses `dev` mode for the demo (data stored in memory, auto-unsealed). In production, Vault would run in `ha` mode with persistent storage and external unseal keys. The architecture supports both without changes to dependent components.

See [Secrets Management](../../../concepts/secrets-management.md) for the complete secrets flow.

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
