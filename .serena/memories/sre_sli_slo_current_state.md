# SRE/SLI/SLO — Estado actual consolidado (2025-12-19)

## Filosofia y parametros de demo
- Arquitectura SRE “prod-like” con tradeoffs de demo: ventana SLO 6h, targets relajados, prioridad a auto‑remediacion.
- Stack: Prometheus Operator (kube-prometheus-stack), Loki (singleBinary), Fluent Bit, Grafana, Pyrra.

## SLOs activos y SLIs validados
**Gateway API**
- Availability SLO: errors/total con `envoy_cluster_upstream_rq{envoy_response_code=~"5.."}`.
- Latency SLO: `envoy_cluster_upstream_rq_time_bucket` (p95, 200ms) ya existe.

**Loki**
- Ingest availability SLO: `loki_request_duration_seconds_count` con `route=push|ingest`.
- Query latency SLO: rutas HTTP y gRPC combinadas para evitar series vacias (query_range y /logproto.Querier/*).

**ArgoCD**
- Sync availability SLO: `argocd_app_sync_total` por `phase`.
- Health SLO complementario: `argocd_app_info{health_status!="Healthy"}` (bool/ratio).
- Latencia reconcile (nuevo, listo para aplicar): `argocd_app_reconcile_bucket` con umbral `le="16"`, p95.

**ExternalSecrets (ESO)**
- SLIs validados: `externalsecret_sync_calls_total`, `externalsecret_sync_calls_error`, `externalsecret_status_condition`, `externalsecret_reconcile_duration`, `externalsecret_provider_api_calls_count`.
- SLO recomendado (e2e readiness): `externalsecret_status_condition{condition="Ready",status!="True"}`.

**Vault API**
- SLIs validados: `vault_core_response_status_code`, `vault_core_handle_request` (summary p99), `vault_core_in_flight_requests`.
- Availability SLO usa `vault_core_response_status_code{type="5xx"}`.

**Argo Workflows**
- SLIs disponibles: `argo_workflows_error_count`, `argo_workflows_k8s_request_total`, `argo_workflows_k8s_request_duration_bucket`.
- No hay success rate real por workflow (faltante `argo_workflows_count`).

## Configuracion Pyrra / Observabilidad
- Pyrra chart 0.19.2, SLOs en `K8s/observability/slo/*.yaml`.
- PrometheusRule generadas por Pyrra (ownerReferences a SLOs).
- Fix aplicado: `prometheusUrl` apunta a `prometheus-operated.observability.svc.cluster.local`.
- Features activadas en Pyrra values: dashboards, webhook validation, generic rules, prometheusRule, serviceMonitorOperator.
- Grafana expuesta via Gateway HTTPRoute; Loki solo ClusterIP.

## Golden Signals cubiertos (hoy)
- Errors/availability: Gateway, Loki ingest, ArgoCD sync/health, Vault, ESO.
- Latency: Gateway p95, Loki query p95, ArgoCD reconcile p95 (pendiente aplicar).
- Traffic/Saturation: disponibles como SLIs (queries en inventario SLI).
