# Inventario SLI + PromQL (validado en Prometheus) — 2025-12-19

Contexto: consultas realizadas vía MCP de Grafana a datasource `prometheus`.
Dashboards de referencia: `K8S Dashboard EN` (UID StarsL_en_K8S) y `ArgoCD` (UID qPkgGHg7k).

## 1) ExternalSecrets (ESO)
**Métricas confirmadas**:
- `externalsecret_sync_calls_total`
- `externalsecret_sync_calls_error`
- `externalsecret_status_condition` (labels: condition, status, name, namespace, ...)
- `externalsecret_reconcile_duration`
- `externalsecret_provider_api_calls_count` (labels: provider, status, call)

**SLI Errors (SLO principal, provider e2e)**
```
errors = rate(externalsecret_provider_api_calls_count{provider="HashiCorp/Vault",status!="success"}[5m])
total  = rate(externalsecret_provider_api_calls_count{provider="HashiCorp/Vault"}[5m])
```

**SLI Availability end-to-end (secret listo)**
```
errors = count(externalsecret_status_condition{condition="Ready",status!="True"})
total  = count(externalsecret_status_condition{condition="Ready"})
```

**SLI Latency (sin histogramas)**
```
avg_reconcile = rate(externalsecret_reconcile_duration[5m]) / rate(externalsecret_sync_calls_total[5m])
```

**SLI Traffic**
```
rate(externalsecret_sync_calls_total[5m])
```

**SLI Saturation (infra)**
```
irate(container_cpu_usage_seconds_total{namespace="external-secrets",container!=""}[2m])
container_memory_working_set_bytes{namespace="external-secrets",container!=""}
```

## 2) Vault API
**Métricas confirmadas**:
- `vault_core_handle_request_count`
- `vault_core_handle_request_sum`
- `vault_core_handle_request` (summary, label `quantile`)
- `vault_core_response_status_code` (labels: code, type)
- `vault_core_in_flight_requests`

**SLI Errors (reemplazo del label inexistente `status`)**
```
errors = rate(vault_core_response_status_code{type="5xx"}[5m])
total  = rate(vault_core_response_status_code[5m])
```

**SLI Latency (p99 real, summary)**
```
p99 = vault_core_handle_request{quantile="0.99"}
```

**SLI Traffic**
```
rate(vault_core_handle_request_count[5m])
```

**SLI Saturation**
```
vault_core_in_flight_requests
# + CPU/mem del pod vault (infra)
```

## 3) Gateway API (Envoy / Cilium)
**Métricas confirmadas**:
- `envoy_cluster_upstream_rq`
- `envoy_cluster_upstream_rq_time_bucket`
 (Envoy / Cilium)
**Métricas confirmadas**:
- `envoy_cluster_upstream_rq`
- `envoy_cluster_upstream_rq_time_bucket`

**SLI Errors (SLO principal)**
```
errors = rate(envoy_cluster_upstream_rq{envoy_response_code=~"5.."}[5m])
total  = rate(envoy_cluster_upstream_rq[5m])
```

**SLI Latency**
```
hist = envoy_cluster_upstream_rq_time_bucket
```

**SLI Traffic**
```
rate(envoy_cluster_upstream_rq[5m])
```

**SLI Saturation (infra + red)**
```
# cilium-envoy
irate(container_cpu_usage_seconds_total{namespace="kube-system",container="cilium-envoy"}[2m])
container_memory_working_set_bytes{namespace="kube-system",container="cilium-envoy"}
# network throughput
irate(container_network_receive_bytes_total{namespace="kube-system",container="cilium-envoy"}[2m])
irate(container_network_transmit_bytes_total{namespace="kube-system",container="cilium-envoy"}[2m])
```

## 4) Loki Ingest
**Métrica confirmada**:
- `loki_request_duration_seconds_bucket` (labels: route, status_code)

**SLI Errors (ingest)**
```
errors = rate(loki_request_duration_seconds_count{route=~"(?i).*(push|ingest).*",status_code=~"5.."}[5m])
total  = rate(loki_request_duration_seconds_count{route=~"(?i).*(push|ingest).*"}[5m])
```

**SLI Latency (ingest)**
```
hist = loki_request_duration_seconds_bucket{route=~"(?i).*(push|ingest).*"}
```

**SLI Traffic (ingest)**
```
rate(loki_request_duration_seconds_count{route=~"(?i).*(push|ingest).*"}[5m])
```

**SLI Saturation (infra)**
```
# CPU/mem del pod loki + disk
container_cpu_usage_seconds_total{namespace="observability",pod=~"loki.*"}
container_memory_working_set_bytes{namespace="observability",pod=~"loki.*"}
# disk via kubelet volume stats (si aplica)
```

## 5) ArgoCD Sync
**Métricas confirmadas**:
- `argocd_app_info` (labels: health_status, sync_status)
- `argocd_app_sync_total` (label: phase)
- `argocd_app_reconcile_bucket`
- `argocd_app_sync_duration_seconds_total`

**SLI Errors (sync)**
```
errors = rate(argocd_app_sync_total{phase=~"Failed|Error|Unknown"}[5m])
total  = rate(argocd_app_sync_total[5m])
```

**SLI Latency (reconcile)**
```
hist = argocd_app_reconcile_bucket
```

**SLI Latency (avg sync)**
```
avg = rate(argocd_app_sync_duration_seconds_total[5m]) / rate(argocd_app_sync_total[5m])
```

**SLI Traffic**
```
rate(argocd_app_sync_total[5m])
```

**SLI Saturation (infra)**
```
# application-controller CPU/mem
container_cpu_usage_seconds_total{namespace="argocd",container="application-controller"}
container_memory_working_set_bytes{namespace="argocd",container="application-controller"}
```

**SLI User-centric complementario (health)**
```
errors = count(argocd_app_info{health_status!="Healthy"})
total  = count(argocd_app_info)
```

## 6) Argo Workflows (brecha)
**Métricas confirmadas**:
- `argo_workflows_error_count`
- `argo_workflows_k8s_request_total`
- `argo_workflows_k8s_request_duration_bucket`
- `argo_workflows_workflow_condition` (labels: type, status; sin id de workflow)

**SLI Errors (proxy actual, NO user-centric)**
```
errors = rate(argo_workflows_error_count[5m])
# total como proxy:
 total = rate(argo_workflows_k8s_request_total[5m])
```

**SLI Latency (proxy)**
```
hist = argo_workflows_k8s_request_duration_bucket
```

**SLI Traffic (proxy)**
```
rate(argo_workflows_k8s_request_total[5m])
```

**SLI Saturation (infra)**
```
container_cpu_usage_seconds_total{namespace="cicd",pod=~"argo-workflows.*"}
container_memory_working_set_bytes{namespace="cicd",pod=~"argo-workflows.*"}
argo_workflows_queue_unfinished_work
```

**Brecha**: no existe métrica de success rate por workflow (`argo_workflows_count` no está). Requiere instrumentación o habilitar métricas específicas de workflows para SLO correcto.

---

# Cobertura Golden Signals (SLOs activos)

## ExternalSecrets (ESO)
- Errors: `externalsecret_provider_api_calls_count` (Vault provider)
- Latency: `externalsecret_reconcile_duration` (avg)
- Traffic: `externalsecret_sync_calls_total`
- Saturation: `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`

## Vault API
- Errors: `vault_core_response_status_code{type="5xx"}`
- Latency: `vault_core_handle_request{quantile="0.99"}`
- Traffic: `vault_core_handle_request_count`
- Saturation: `vault_core_in_flight_requests` + CPU/mem

## Gateway API (Envoy/Cilium)
- Errors: `envoy_cluster_upstream_rq{envoy_response_code=~"5.."}`
- Latency: `envoy_cluster_upstream_rq_time_bucket` (p95)
- Traffic: `envoy_cluster_upstream_rq`
- Saturation: CPU/mem + `container_network_*`

## Loki Ingest
- Errors: `loki_request_duration_seconds_count{route=~"push|ingest",status_code=~"5.."}`
- Latency: `loki_request_duration_seconds_bucket{route=~"push|ingest"}` (p95)
- Traffic: `loki_request_duration_seconds_count{route=~"push|ingest"}`
- Saturation: CPU/mem + disk usage

## Loki Query Latency
- Latency: `loki_request_duration_seconds_bucket{route=~"(loki_api_v1_query_range|/logproto.Querier/Query|/logproto.Querier/QuerySample)",le="5"}`
- Total: `loki_request_duration_seconds_count{route=~"(loki_api_v1_query_range|/logproto.Querier/Query|/logproto.Querier/QuerySample)"}`
- Nota: en despliegue single-binary/no-microservices, las queries pueden ir por rutas gRPC (`/logproto.Querier/*`) y no por `loki_api_v1_query_range`; por eso el SLO agrega ambas para evitar series vacías.

## ArgoCD Sync + Health
- Errors: `argocd_app_sync_total{phase=~"Failed|Error|Unknown"}`
- Latency: `argocd_app_reconcile_bucket` (p95)
- Traffic: `argocd_app_sync_total`
- Saturation: CPU/mem (application-controller)
- Health SLI complementario: `argocd_app_info{health_status!="Healthy"}`
