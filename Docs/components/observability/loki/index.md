# loki

![Version: 6.42.0](https://img.shields.io/badge/Version-6.42.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://grafana.com/oss/loki)

Log aggregation system designed to store and query logs

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `6.42.0` |
| **Chart Type** | `application` |
| **Upstream Project** | [loki](https://grafana.com/oss/loki) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Loki?

Loki is a log aggregation system designed for resource efficiency. It indexes logs by labels (like Prometheus does for metrics) rather than indexing the full text of every log line. This dramatically reduces storage and resource requirements.

Performance and scalability matter here. Loki can run as a single binary in edge deployments (like this one) or scale to massive distributed clusters without architectural changes. The resource footprint in single-binary mode is minimal.

Integration with Grafana is tight. You write LogQL queries (similar syntax to PromQL) to search logs, filter by labels, and correlate with metrics. Logs and metrics share the same label namespace, making correlation straightforward.

## Architecture Role

Loki operates at **Layer 1** of the platform, the Platform Services layer. It's part of the observability stack.

Key integration points:

- **Fluent-bit**: Receives logs forwarded from every node
- **Grafana**: Configured as a data source for log queries
- **Prometheus**: Shares label conventions for easier correlation

The configuration here runs in single-binary mode with filesystem storage and a 6-hour retention period. This is appropriate for a demo environment. In a production environment, you'd use object storage (S3, GCS, Azure Blob) and longer retention.

See [Observability Model](../../../architecture/observability.md) for how Loki fits into the complete stack.

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend | object | `{"replicas":0}` | Disable backend replicas (not used in single-binary mode). |
| chunksCache | object | `{"enabled":false}` | Disable memcached chunks cache (not needed in SingleBinary mode). |
| deploymentMode | string | `"SingleBinary"` | Deploy Loki as a single monolithic binary. See https://grafana.com/docs/loki/latest/get-started/deployment-modes/ |
| gateway | object | `{"enabled":false}` | Disable gateway (not needed in SingleBinary mode). |
| loki.storage | object | `{"type":"filesystem"}` | Storage backend configuration (filesystem for demo). |
| loki.structuredConfig | object | `{"auth_enabled":false,"common":{"path_prefix":"/var/loki","replication_factor":1,"storage":{"filesystem":{"chunks_directory":"/var/loki/chunks","rules_directory":"/var/loki/rules"}}},"compactor":{"delete_request_store":"filesystem","retention_enabled":true,"working_directory":"/var/loki/compactor"},"limits_config":{"retention_period":"6h"},"schema_config":{"configs":[{"from":"2024-01-01","index":{"period":"24h","prefix":"index_"},"object_store":"filesystem","schema":"v13","store":"tsdb"}]},"server":{"grpc_listen_port":9095,"http_listen_port":3100},"storage_config":{"boltdb_shipper":{"active_index_directory":"/var/loki/boltdb-shipper-active","cache_location":"/var/loki/boltdb-shipper-cache","cache_ttl":"24h"},"filesystem":{"directory":"/var/loki/chunks"}}}` | This section uses the modern, structured configuration format. |
| lokiCanary | object | `{"enabled":false}` | Disable canary (testing component, not needed for demo). |
| memberlist | object | `{"enable_ipv6":false}` | Disable IPv6 for the memberlist. |
| read | object | `{"replicas":0}` | Disable read replicas (not used in single-binary mode). |
| resultsCache | object | `{"enabled":false}` | Disable memcached results cache (not needed in SingleBinary mode). |
| singleBinary.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ready","port":"http-metrics"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":1}` | Liveness probe for the single binary pod. |
| singleBinary.persistence | object | `{"enabled":true,"size":"2Gi"}` | Persistence configuration for the single binary. |
| singleBinary.priorityClassName | string | `"platform-observability"` |  |
| singleBinary.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ready","port":"http-metrics"},"initialDelaySeconds":15,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Readiness probe for the single binary pod. |
| singleBinary.replicas | int | `1` | Number of replicas for the single binary. |
| singleBinary.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resource limits and requests for Loki. |
| test | object | `{"enabled":false}` | Disable test (not needed for demo, requires canary to be enabled). |
| write | object | `{"replicas":0}` | Disable write replicas (not used in single-binary mode). |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
