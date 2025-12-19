# SRE & Observability Architecture Strategy

This document outlines the architectural decisions, trade-offs, and implementation details for the SRE and Observability stack within the IDP Blueprint.

## Core Philosophy: "Resilience over Perfection"
- **Production Architecture, Pragmatic Implementation:** The architecture mirrors a high-maturity production environment (GitOps, SLOs, Self-healing) but is implemented with resource-constrained components suitable for ephemeral environments.
- **The "125V Standard":** We design for high robustness (400V) but guarantee a realistic operational level (125V). In a constrained demo environment (Laptop/k3d with <12GB RAM), we prioritize **Self-Healing** over instant availability.
- **Automated Operations:** The platform must be self-managing. Alerts should trigger only when automation fails to resolve an issue within a reasonable timeframe (~15-20 mins).

## Stack Components

### 1. Metrics (Prometheus Stack)
- **Deployment:** `kube-prometheus-stack` via Helm.
- **Optimization:** 
  - `kube-state-metrics` and `node-exporter` configured with strict whitelists and label dropping (e.g., removing `uid`, `container_id`) to minimize cardinality.
  - Retention set to **24h**.
  - Storage: 1Gi local PVC.

### 2. Logging (Loki)
- **Deployment:** `grafana/loki` (Chart v6.x+) in **SingleBinary** mode.
- **Monitoring:** Explicit `ServiceMonitor` enabled for Prometheus visibility.
- **Storage:** Filesystem (BoltDB shipper + chunks on disk). No S3 dependency.
- **Configuration:** 
  - Schema v13 with 24h index rotation.
  - Read/Write replicas disabled.
  - Caching layers (memcached) disabled to save memory.
  - **Fluent-bit Tuning:** Kubernetes Filter `Buffer_Size` set to `0` (unlimited) to handle large pod specifications (~40k-65k) without metadata loss. Output buffer set to `64k` for balanced batching.

### 3. Service Level Objectives (Pyrra)
- **Role:** SLO management and Error Budget tracking.
- **Demo Trade-off:** Window set to **6h** (vs standard 28d). This allows visualizing error budget burn and alerting within a single demo session.
- **Targets ("Kinder Percentages"):** SLOs are calibrated to absorb scheduler latency, cold starts, and self-healing time without generating noise.

| Component | SLO Type | Target | Error Budget (6h) | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Gateway API** | Availability | **98.0%** | ~7.2 min | Critical access. Tolerates Envoy restarts but demands quick recovery. |
| **Secrets (Vault)** | Sync Success | **97.0%** | ~10.8 min | High tolerance for injection latency due to CPU pressure on operators. |
| **ArgoCD** | Sync Success | **95.0%** | ~18 min | Tolerates git flakes, network glitches, and long reconciliation loops. |
| **Loki** | Ingest Availability | **95.0%** | ~18 min | Logging is secondary to user traffic during resource contention. |
| **Argo Workflows** | Controller Stability | **99.0%** | ~3.6 min | Monitors controller panics vs activity. Essential for CI/CD reliability. |

### 4. Alerting & Self-Healing (The Loop)
A closed-loop remediation system is implemented:
1.  **Detect:** Prometheus fires alert based on Pyrra SLO burn rate (grouped by `name`, `namespace`, `envoy_cluster_name` for context).
2.  **Route:** Alertmanager routes critical SLO alerts to `argo-events-webhook`.
3.  **Ingest:** Argo Events `EventSource` receives the webhook.
4.  **Trigger:** Argo Events `Sensor` (`slo-remediation`) matches the alert payload and extracts context labels.
5.  **Act:** An Argo Workflow (e.g., `remediate-externalsecret-failure`) is triggered to attempt automatic resolution (e.g., deleting a stuck ExternalSecret to force re-sync).

## Service Level Agreements (SLA)
While this is a blueprint for internal use, we define SLAs to contractually align user expectations with the platform's capabilities (based on the "125V Standard").

- **Service Hours:** 24/7 (Autonomous), Human Support Best Effort.
- **RPO (Data Loss):** 24h (Ephemeral persistence).

| Service | SLO (Internal Goal) | SLA (User Commitment) | Definition | Consequence |
| :--- | :--- | :--- | :--- | :--- |
| **API Gateway** | 99.9% | **99.0%** | Ingress availability. | Demo Interruption. |
| **Pipeline (Argo)** | 99.0% | **95.0%** | Sync success <15m. | Deployment Delay. |
| **Secret Management** | 97.0% | **95.0%** | Injection availability. | Pod Start Failure. |
| **Developer Portal** | 95.0% | **90.0%** | UI Access. | Visibility Loss. |

## Incident Post-Mortem: Log Ingestion Failure (2025-12-19)
**Issue:** Complete log data loss for namespaces `cicd` and `argocd`.
**Root Cause:** The Fluent-bit `kubernetes` filter failed to enrich logs because the Pod Specification JSON for complex pods (SonarQube, Argo controllers) exceeded the default 32KB buffer size. The HTTP client threw: `[warn] [http_client] cannot increase buffer: current=32000 requested=64768 max=32000`.
**Resolution:** Explicitly set `Buffer_Size 0` in the Kubernetes filter configuration to allow dynamic buffer resizing.
**Lesson Learned:** Equalizing buffers (e.g., 64k) is only effective if the payload + overhead is strictly below that limit. For metadata enrichment of unpredictable Pod Specs, the modern Fluent-bit recommendation is using `0` (unlimited) to prioritize data integrity over strict memory capping.

## Constraints & Limits
- **Memory Target:** Total observability stack < 2GB RAM.
- **Headroom:** With heavy workloads (SonarQube, Backstage), the cluster operates near memory limits. SLOs are the buffer that prevents this friction from becoming "Page Duty" noise.
- **Persistence:** Optimized for <24h lifespan.

## Validation
- Verify SLOs: `kubectl get prometheusrules -n observability`
- Check Metrics: Verify targets in Prometheus (Status -> Targets).
- Verify Pipeline: Trigger error -> Check Alertmanager -> Check Argo Events logs -> Check Workflow execution.
