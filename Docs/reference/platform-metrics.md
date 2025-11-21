# Platform Metrics & Observability

This document describes the metrics, SLIs (Service Level Indicators), and observability practices for the IDP Blueprint platform itself—not the applications running on it.

## Platform Health vs Application Health

It's important to distinguish between two types of metrics:

- **Application Metrics:** Metrics from workloads deployed by users (request latency, error rates, business KPIs)
- **Platform Metrics:** Metrics about the IDP infrastructure itself (ArgoCD sync status, Prometheus uptime, cluster resource usage)

This document focuses on platform metrics: how to monitor the health of the IDP components and the Kubernetes cluster.

## Key Platform Components to Monitor

### 1. GitOps Engine — ArgoCD

ArgoCD is the heart of the platform. If it fails, automated deployments stop.

**Metrics to track:**

- **Sync Status:** Are Applications in sync with Git?
  - Metric: `argocd_app_info{sync_status="OutOfSync"}`
  - Goal: 0 applications out of sync (excluding temporary drift)

- **Sync Failures:** Are syncs failing?
  - Metric: `argocd_app_sync_total{phase="Failed"}`
  - Goal: < 1% failure rate

- **Reconciliation Lag:** How long does it take ArgoCD to detect and reconcile changes?
  - Metric: `argocd_app_reconcile_duration_seconds`
  - Goal: P95 < 60s

**Where to find:**

- ArgoCD exposes Prometheus metrics via ServiceMonitor
- Grafana dashboard: ArgoCD Application Overview

### 2. Policy Engine — Kyverno

Kyverno validates resources on admission. If it's down, policies aren't enforced.

**Metrics to track:**

- **Policy Violations (Audit Mode):** How many resources violate policies?
  - Metric: `kyverno_policy_results_total{policy_result="fail"}`
  - Goal: Trending down over time (improving compliance)

- **Admission Webhook Latency:** Does Kyverno slow down deployments?
  - Metric: `kyverno_admission_requests_duration_seconds`
  - Goal: P95 < 500ms

- **Webhook Availability:** Is Kyverno's admission webhook reachable?
  - Metric: `kyverno_admission_requests_total{status_code="500"}`
  - Goal: 0 failures

**Where to find:**

- Kyverno exposes Prometheus metrics
- PolicyReports via Policy Reporter dashboard

### 3. Observability Stack

If Prometheus or Loki fail, you lose visibility into the platform.

**Metrics to track:**

**Prometheus:**

- **Scrape Success Rate:** Are targets being scraped successfully?
  - Metric: `up{job="<target>"}`
  - Goal: > 99% uptime per target

- **Storage Usage:** Is Prometheus running out of disk?
  - Metric: `prometheus_tsdb_storage_blocks_bytes`
  - Goal: < 80% of allocated storage

- **Query Performance:** Are queries slow?
  - Metric: `prometheus_http_request_duration_seconds{handler="/api/v1/query"}`
  - Goal: P95 < 1s

**Loki:**

- **Ingestion Rate:** Are logs being ingested?
  - Metric: `loki_ingester_chunks_created_total`
  - Goal: Matches expected log volume

- **Query Latency:** Are log queries fast?
  - Metric: `loki_request_duration_seconds{route="loki_api_v1_query_range"}`
  - Goal: P95 < 5s

**Where to find:**

- Grafana dashboards for Prometheus and Loki (included in kube-prometheus-stack)

### 4. Secrets Management

If Vault or External Secrets fail, applications can't access credentials.

**Metrics to track:**

**Vault:**

- **Sealed Status:** Is Vault unsealed?
  - Metric: `vault_core_unsealed`
  - Goal: 1 (unsealed)

**External Secrets:**

- **Sync Success:** Are ExternalSecrets syncing successfully?
  - Metric: `externalsecret_sync_calls_total{status="success"}`
  - Goal: > 99% success rate

- **Sync Lag:** How long does it take to sync a secret change?
  - Metric: Time between Vault update and Kubernetes Secret update
  - Goal: < 60s (depends on refresh interval)

**Where to find:**

- External Secrets exposes Prometheus metrics via ServiceMonitor

### 5. Cluster Resources

The Kubernetes cluster itself needs monitoring.

**Metrics to track:**

- **Node Status:** Are nodes healthy?
  - Metric: `kube_node_status_condition{condition="Ready",status="true"}`
  - Goal: All nodes Ready

- **CPU Usage:** Is the cluster under CPU pressure?
  - Metric: `node_cpu_seconds_total` (via node-exporter)
  - Goal: < 70% average utilization

- **Memory Usage:** Is the cluster running out of memory?
  - Metric: `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes`
  - Goal: > 20% available memory

- **Disk Usage:** Are nodes running out of disk?
  - Metric: `node_filesystem_avail_bytes / node_filesystem_size_bytes`
  - Goal: > 20% available disk

**Where to find:**

- Grafana dashboards: Kubernetes / Nodes, Kubernetes / Compute Resources

## Platform SLIs and SLOs

Service Level Indicators (SLIs) are metrics that measure a specific aspect of service quality. Service Level Objectives (SLOs) are targets for those SLIs.

### Proposed Platform SLOs

| Component | SLI | SLO | Measurement Window |
|-----------|-----|-----|-------------------|
| **ArgoCD** | Application Sync Success Rate | > 99% | 30 days |
| **Kyverno** | Admission Webhook Availability | > 99.5% | 30 days |
| **Prometheus** | Scrape Target Availability | > 99% per target | 7 days |
| **Loki** | Log Ingestion Success Rate | > 99% | 7 days |
| **External Secrets** | Secret Sync Success Rate | > 99% | 30 days |
| **Kubernetes API** | API Request Success Rate | > 99.9% | 7 days |
| **Cluster Nodes** | Node Uptime | > 99% | 30 days |

### Error Budgets

An error budget is the allowable amount of failure before violating an SLO.

Example: If the ArgoCD SLO is 99% sync success over 30 days, the error budget is 1%, which translates to approximately 7.2 hours of downtime or failures.

**Using error budgets:**

- **Green (Budget Remaining):** Continue normal development velocity
- **Yellow (Budget Low):** Focus on stability, defer risky changes
- **Red (Budget Exhausted):** Freeze deployments, fix reliability issues

**Tool:** Pyrra is configured in the observability stack for SLO tracking and burn rate alerting. It integrates with Prometheus and generates alerts when error budgets are being consumed too quickly.

## Current Gaps and Future Work

### 1. No HorizontalPodAutoscalers (HPAs)

**Current State:** Components run with fixed replica counts. There's no auto-scaling based on load.

**Gap:** If a component (e.g., ArgoCD) experiences high load, it won't scale automatically. This could lead to degraded performance or failures.

**Future Work:** Define HPAs for critical components based on CPU/memory usage or custom metrics (e.g., ArgoCD queue depth).

### 2. Limited Resource Utilization Tracking

**Current State:** Resource requests and limits are set, but there's no automated analysis of actual vs requested resources.

**Gap:** Components may be over-provisioned (wasting resources) or under-provisioned (risking OOMKills).

**Future Work:**

- Use tools like Goldilocks or VPA (Vertical Pod Autoscaler) to recommend optimal resource requests
- Monitor actual resource usage vs requests via Prometheus
- Create dashboards showing resource efficiency

### 3. No Automated Alerting for Platform SLOs

**Current State:** Metrics are collected, but there are no configured alerts for platform SLO violations.

**Gap:** If ArgoCD sync success rate drops below 99%, there's no automatic alert.

**Future Work:**

- Define PrometheusRule resources for each platform SLO
- Configure alerting routes in Alertmanager (currently enabled for Pyrra)
- Create runbooks for each alert

### 4. Limited Capacity Planning

**Current State:** The platform runs in a fixed 3-node cluster. There's no forecasting of when resources will be exhausted.

**Gap:** If workload growth is high, the cluster could run out of capacity without warning.

**Future Work:**

- Track resource usage trends over time
- Project when capacity limits will be reached
- Define capacity thresholds that trigger planning discussions

## Accessing Platform Metrics

### Via Grafana Dashboards

Pre-configured dashboards are available in Grafana:

- **Kubernetes / Compute Resources / Cluster:** Overall cluster resource usage
- **Kubernetes / Compute Resources / Namespace:** Per-namespace resource consumption
- **ArgoCD:** Application sync status and performance
- **Kyverno:** Policy compliance and webhook performance
- **Prometheus:** Prometheus self-monitoring
- **Loki:** Loki ingestion and query performance

**Access:** Navigate to Grafana UI (see [URLs & Credentials](urls-credentials.md))

### Via Prometheus Queries

For ad-hoc analysis, query Prometheus directly:

**Example queries:**

```promql
# Applications out of sync
count(argocd_app_info{sync_status="OutOfSync"})

# Pod CPU usage by namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Policy violations in the last hour
increase(kyverno_policy_results_total{policy_result="fail"}[1h])
```

**Access:** Navigate to Prometheus UI or use Grafana Explore

### Via Loki Queries

For log-based analysis:

```logql
# ArgoCD sync errors
{app="argocd-application-controller"} |= "sync failed"

# Kyverno policy violations
{app="kyverno"} |= "policy violation"
```

**Access:** Use Grafana Explore with Loki data source

## Best Practices for Platform Monitoring

1. **Monitor the Monitors:** Ensure Prometheus itself is healthy. Use federation or external monitoring if needed.

2. **Alert on Symptoms, Not Causes:** Alert on user-facing issues (sync failures, high latency) rather than low-level metrics (CPU usage). Investigate causes after detecting symptoms.

3. **Reduce Alert Fatigue:** Only alert on conditions that require human intervention. Use Pyrra burn rate alerts instead of threshold alerts.

4. **Runbooks for Alerts:** Every alert should have a corresponding runbook explaining how to diagnose and resolve it.

5. **Regular Review:** Review platform metrics weekly. Look for trends, not just anomalies.

## References

- [Prometheus Component](../components/observability/prometheus/index.md): Metrics collection
- [Grafana Component](../components/observability/grafana/index.md): Visualization
- [ArgoCD Component](../components/infrastructure/argocd/index.md): GitOps engine
- [Kyverno Component](../components/policy/kyverno/index.md): Policy engine
- [Observability Model](../architecture/observability.md): Overall observability architecture
