# Observability Architecture (validated 2025-12-27)

## Overview
- **Metrics**: Prometheus Operator (Prometheus, Alertmanager).
- **Logging**: Fluent Bit (Collector) → Loki (Store).
- **Visualisation**: Grafana.
- **SLO/SRE**: Pyrra (SLO CRDs -> Prometheus Rules).
- **Retention**: Aggressive **24h retention** policies for both Metrics and Logs to fit laptop storage constraints.

## 1. Metrics Pipeline (Prometheus)
- **Deployment**: `kube-prometheus-stack` (StatefulSet).
- **Configuration**:
  - **Scraping**: Global scrape interval `60s`. `serviceMonitorSelector` and `podMonitorSelector` are empty (`{}`) to select all monitors across all namespaces.
  - **Storage**: `1Gi` PVC.
  - **Retention**: `24h`.
  - **Exporters**: `node-exporter` (minimal collectors), `kube-state-metrics` (whitelisted resources).

## 2. Logging Pipeline (Loki)
- **Store**: Loki (SingleBinary mode).
  - **Storage**: Filesystem backend (Chunks/Rules), `2Gi` PVC.
  - **Retention**: `24h` (Compactor enabled, index period 24h).
- **Collector**: Fluent Bit (DaemonSet).
  - **Output**: Pushes to `http://loki.observability.svc.cluster.local:3100`.
  - **Filtering**: Lua filter drops the `default` namespace and high-cardinality labels to reduce noise/volume.
  - **Labels**: `namespace`, `container`, `pod`, `stream`, `app`.

## 3. Visualisation (Grafana)
- **Datasources**:
  - **Prometheus** (Default).
  - **Loki** (Proxy access).
  - **Alertmanager**.
- **Dashboard Provisioning**:
  - **Sidecar**: Enabled with `searchNamespace: ALL`.
  - **Discovery**: Scans for ConfigMaps with label `grafana_dashboard` (value ignored).
  - **Pre-loaded**: K8s mixins, ArgoCD, Cert-Manager, Cilium, Kyverno, Trivy, Loki logs.
- **Integration**:
  - `allow_embedding: true` (for Backstage integration).
  - Admin credentials managed via External Secrets (`grafana-admin-credentials`).

## 4. SLO/SRE (Pyrra)
- **Component**: Pyrra (Deployment).
- **Flow**: User creates `ServiceLevelObjective` CRs -> Pyrra generates `PrometheusRule`.
- **Alerting**: Multi-window burn rate alerts routed to Alertmanager.
- **Current State**:
  - SLOs defined for ArgoCD, ExternalSecrets, Gateway, Loki, Vault.
  - **Gaps**: Vault histogram metrics missing (latency SLO invalid). Argo Workflows metrics missing (availability SLO NoData).

## 5. Alerting
- **Alertmanager**: Configured to route alerts to Argo Events (`http://alertmanager-eventsource-svc.argo-events.svc.cluster.local:12000/webhook`) for automation triggers.
