# SRE / SLI / SLO — Current State (validated 2025-12-27)

## SLOs applied in cluster (CRs present)
Namespace: `observability`
- `argo-workflows-controller-availability` — window 6h, target 99.0
- `argocd-application-health` — window 6h, target 99.0
- `argocd-reconcile-latency-p95` — window 6h, target 95.0
- `argocd-sync-availability` — window 6h, target 95.0
- `externalsecrets-sync-success` — window 6h, target 97.0
- `gateway-api-availability` — window 6h, target 98.0
- `gateway-api-latency-p95` — window 6h, target 95.0
- `loki-ingest-availability` — window 6h, target 95.0
- `loki-query-latency-p95` — window 6h, target 95.0
- `vault-api-availability` — window 6h, target 97.0

## SLO query basis (repo)
- Gateway API availability/latency: `envoy_cluster_upstream_rq` and `envoy_cluster_upstream_rq_time_bucket`.
- Loki ingest availability: `loki_request_duration_seconds_count{route=~"(?i).*(push|ingest).*"}`.
- Loki query latency: `loki_request_duration_seconds_bucket` for `query_range` and gRPC query routes.
- ArgoCD sync/health: `argocd_app_sync_total`, `argocd_app_info{health_status="Healthy"}`.
- ArgoCD reconcile latency: `argocd_app_reconcile_bucket` (p95 under 16s).
- External Secrets: `externalsecret_status_condition{condition="Ready",status="True"}`.
- Vault availability: `vault_core_response_status_code`.
- Argo Workflows controller availability: `argo_workflows_error_count` and `argo_workflows_k8s_request_total`.

## Pyrra deployment (repo + cluster)
- Chart version: **0.19.2** (`K8s/observability/pyrra/Chart.yaml`).
- Image running in cluster: `ghcr.io/pyrra-dev/pyrra:v0.9.2`.
- `prometheusUrl`: `http://prometheus-operated.observability.svc.cluster.local:9090`.
- Features enabled in values: dashboards, validating webhook, generic rules, prometheusRule, serviceMonitor + serviceMonitorOperator.
- Grafana dashboards present: **Pyrra - List** (UID `YuUMRZ44z`), **Pyrra - Detail** (UID `ccssRIenz`).

## Metric availability (cluster)
- **ArgoCD:** `argocd_app_*` metrics present in Prometheus.
- **External Secrets:** `externalsecret_status_condition` present.
- **Vault:** `vault_core_*` metrics present; **no** `vault_core_handle_request_bucket` histogram metrics.
- **Argo Workflows:** no `argo_workflows_*` metrics present; `argo_workflows_count` is absent.

## Implications / Gaps
- Vault latency SLO cannot be built from histograms (none exported).
- Argo Workflows SLOs will evaluate to **NoData** until workflows metrics are exposed or the stack is deployed.
