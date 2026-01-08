# Observability Architecture (validated 2025-12-27)

## Overview
- **Metrics**: Prometheus Operator (Prometheus, Alertmanager).
- **Logging**: Fluent Bit (Collector) → Loki (Store).
- **Visualisation**: Grafana.
- **SLO/SRE**: Pyrra (SLO CRDs -> Prometheus Rules).
- **Retention**: Aggressive **24h retention** policies for both Metrics and Logs to fit laptop storage constraints.

## 1. Metrics Pipeline (Prometheus)
- **Deployment**: `kube-prometheus-stack` (StatefulSet) in namespace `observability`.
- **Core Configuration** (all verified from `K8s/observability/kube-prometheus-stack/values.yaml`):
  - **Global Scrape**: Interval `60s` (línea 108), Timeout `40s` (línea 110)
  - **Storage**: `1Gi` PVC (línea 123), **StorageClass: undefined** (usa default del cluster)
  - **Retention**: `24h` (línea 112)
  - **Resources**: CPU 200m/500m, Memory 512Mi/1536Mi (líneas 127-134)
  - **External Labels**: `origin_prometheus: "idp-demo-cluster"` (línea 106)

- **Selectors Vacíos**: `serviceMonitorSelector: {}`, `podMonitorSelector: {}` (líneas 96, 99) - Seleccionan TODOS los namespaces

- **Exporters Habilitados**: 
  - node-exporter: Habilitado con filtros de alta cardinalidad removidos
  - kube-state-metrics: Habilitado con **whitelist** explícito (línea 428)

- **Exporters Explícitamente Deshabilitados** (5 exporters, clave para debuggeo):
  - `etcd: false` (línea 12) - "External etcd or k3d specific"
  - `kubeProxy: false` (línea 20) - "Disabled in exporters section"  
  - `kubeScheduler: false` (línea 27) - "Disabled in exporters section"
  - `kubeEtcd: enabled: false` (líneas 73-74) - "Disables because it doesnt exist in k3s"
  - `kubeControllerManager: enabled: false` (líneas 75-76) - "Disables because it doesnt exist in k3s"
  - `kubeProxy: enabled: false` (líneas 79-80) - "Disables because it doesnt exist in k3s"

- **Resource Exclusions** (IMPORTANTE para performance, no mencionados en memoria original):
  Prometheus IGNORA (ArgoCD resource.exclusions en `IT/argocd/values.yaml` líneas 299-322):
  - Network: Endpoints, EndpointSlice (discovery.k8s.io)
  - Coordination: Lease
  - Auth: TokenReview, SubjectAccessReview, LocalSubjectAccessReview, etc.
  - Certs: CertificateSigningRequest, CertificateRequest
  - Cilium: CiliumIdentity, CiliumEndpoint, CiliumEndpointSlice
  - Kyverno: PolicyReport, ClusterPolicyReport, AdmissionReport, etc.

- **Whitelist Kube-state-metrics** (línea 428):
  ```
  --resources=cronjobs,daemonsets,deployments,jobs,namespaces,networkpolicies,nodes,
  persistentvolumeclaims,persistentvolumes,pods,services,statefulsets,storageclasses
  ```

## 2. Logging Pipeline (Loki + Fluent Bit)
- **Store**: Loki (SingleBinary mode).
  - **Deployment**: Config en `K8s/observability/loki/values.yaml`
  - **Storage**: Filesystem backend (Chunks/Rules), **2Gi PVC** (línea 72), **StorageClass: undefined** (usa default del cluster)
  - **Retention**: `24h` (línea 52, Compactor enabled)
  - **Index period**: 24h (línea 39) - optimizado para demo cortas (<6h)
  - **Resources**: CPU 100m/500m, Memory 512Mi/1Gi (líneas 64-68)
  - **Ingest Rate Limits**: 20MB/s con burst 40MB (líneas 53-54)

- **Collector**: Fluent Bit DaemonSet (config completa en `K8s/observability/fluent-bit/values.yaml`).
  - **Output**: `http://loki.observability.svc.cluster.local:3100` (línea 91)
  
  - **EXCLUSIÓN CRÍTICA del namespace `default`** (evidencia exacta, líneas 188-207): Script Lua devuelve -1 (drop completo)
    - **IMPACTO OPERACIONAL**: Apps desplegadas en namespace `default` **NUNCA** tendrán logs en Loki.

  - **Filtering de High-Cardinality Labels** (líneas 192-201):
    Remueve: `pod-template-hash`, `controller-revision-hash`, `annotations`, `docker_id`, `pod_ip`, `container_image`

  - **Labels Mapeados exactamente** (línea 100): namespace, container, stream, pod, app

  - **Configuración Operacional CRÍTICA**:
    - **Buffer Size**: 64k (línea 106)
    - **Compression**: gzip habilitado (línea 104)
    - **Retry Limit**: 5 intentos (línea 102)
    - **Flush Interval**: 2s (línea 38)

## 3. Visualization (Grafana)
- **Datasources**: Prometheus (Default), Loki (Proxy), Alertmanager

- **Admin Credentials**: ExternalSecret `grafana-admin-credentials`, refreshInterval: 3m

- **Dashboard Provisioning** (SIDEAR AUTO-DISCOVERY, NO "pre-loaded"):
  - **Sidecar**: Enabled, label: `grafana_dashboard` 
  - **Reality Check**: Only fluent-bit and pyrra provide dashboards via ConfigMaps. Others require manual install

- **Integration**: `allow_embedding: true`, **Plugins**: grafana-piechart-panel, grafana-polystat-panel, marcusolsson-json-datasource (líneas 219-222)

## 4. SLO/SRE (Pyrra)
- **Component**: Pyrra v0.19.2 (Deployment, `K8s/observability/pyrra/`)
- **Sync Wave**: "2"
- **Flow**: ServiceLevelObjective CR → Pyrra genera PrometheusRule
- **Alerting**: Multi-window burn rate alerts habilitados

- **SLOs Definidos** (11 archivos en `K8s/observability/slo/`): argocd-* (3), gateway-api-* (2), loki-* (2), secrets-sync, vault-api-availability, argo-workflows-controller-availability

- **Gaps Documentados**:
  1. **Vault Histogram Metrics**: No existe histogram - solo availability SLO posible
  2. **Argo Workflows NoData**: Estado NoData porque FUSE_CICD=false (config.toml línea 11)

## 5. Alerting & Notification
- **Alertmanager**: Configurado en `K8s/observability/kube-prometheus-stack/values.yaml` líneas 57-69
  
- **Receivers**: `null` (silenciar), `argo-events-webhook` (automation)

- **Webhook URL**: `http://alertmanager-eventsource-svc.argo-events.svc.cluster.local:12000/webhook` (línea 68)
  
- **Grouping**: group_by: alertname,cluster,service; group_wait: 10s; group_interval: 10s; repeat_interval: 12h
  - **Impacto**: Evita alert spam, 12h repeat para issues persistentes

- **Inhibit Rules**: **NO configurados**
