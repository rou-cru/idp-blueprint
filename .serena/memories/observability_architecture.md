# Observability Architecture (validated 2025-12-27)

## Overview
- **Metrics**: Prometheus Operator (Prometheus + Alertmanager)
- **Logging**: Fluent Bit → Loki
- **Visualization**: Grafana
- **SLOs**: Pyrra (SLO CRDs → PrometheusRules)
- **Retention**: 24h for Prometheus and Loki

## Metrics (Prometheus)
Source: `K8s/observability/kube-prometheus-stack/values.yaml`.

- **Scrape**: `scrapeInterval: 60s`, `scrapeTimeout: 40s`
- **Selectors**: `serviceMonitorSelector: {}` and `podMonitorSelector: {}` with namespace selectors `{}` (discover across all namespaces)
- **Retention**: `24h`
- **Storage**: `1Gi` PVC (RWO)
- **External label**: `origin_prometheus: "idp-demo-cluster"`
- **Disabled exporters**: `kubeEtcd`, `kubeControllerManager`, `kubeScheduler`, `kubeProxy`
- **kube-state-metrics**: resource whitelist via `--resources=...` (values file)

## Alerting (Alertmanager)
Source: `K8s/observability/kube-prometheus-stack/values.yaml`.

- **Receiver**: `argo-events-webhook` → `http://alertmanager-eventsource-svc.argo-events.svc.cluster.local:12000/webhook`
- **Grouping**: `group_by: ['alertname','cluster','service']`, `group_wait: 10s`, `group_interval: 10s`, `repeat_interval: 12h`
- **send_resolved**: true

## Logging (Loki + Fluent Bit)
Sources: `K8s/observability/loki/values.yaml`, `K8s/observability/fluent-bit/values.yaml`.

- **Loki**: `deploymentMode: SingleBinary`, filesystem storage, `retention_period: 24h`, PVC `2Gi`
- **Ingestion limits**: `ingestion_rate_mb: 20`, `ingestion_burst_size_mb: 40`
- **Fluent Bit output**: `loki.observability.svc.cluster.local:3100`
- **Lua filter**: removes high-cardinality labels and drops logs from `default` namespace

## Grafana
Source: `K8s/observability/kube-prometheus-stack/values.yaml`.

- **Dashboards**: sidecar enabled with `label: grafana_dashboard`, `searchNamespace: ALL`
- **Embedding**: `allow_embedding: true`
- **Datasources**: Loki is defined via `datasources.yaml` in values

## SLOs (Pyrra)
Sources: `K8s/observability/pyrra/` and `K8s/observability/slo/`.

Defined SLOs:
- `argocd-application-health-slo.yaml`
- `argocd-sync-availability-slo.yaml`
- `argocd-reconcile-latency-slo.yaml`
- `gateway-api-availability-slo.yaml`
- `gateway-api-latency-slo.yaml`
- `loki-ingest-availability-slo.yaml`
- `loki-query-latency-slo.yaml`
- `secrets-sync-slo.yaml`
- `vault-api-availability-slo.yaml`
- `argo-workflows-controller-availability-slo.yaml`
