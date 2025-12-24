# Logs - Design and Current State (2025-12-24)

## Scope
Facts and design decisions for the logging pipeline (Fluent Bit → Loki → Grafana). No historical incidents.

## Architecture / Design
- **Pipeline**: Fluent Bit (DaemonSet) tails `/var/log/containers/*.log` and ships to Loki; Grafana consumes Loki.
- **GitOps**: Observability components deployed by `K8s/observability/applicationset-observability.yaml`.
- **Loki**: Single-binary mode, filesystem storage, 24h retention (demo). `K8s/observability/loki/values.yaml`.
- **Grafana datasource**: Loki datasource `uid: Loki` via `kube-prometheus-stack` values.
- **Dashboards**: Log dashboards provisioned from gnet IDs 16976/19566/18042/23789.
- **Isolation dashboard**: *Kubernetes Loki logs* (Grafana uid `NClZGd6nA`) is the **canonical** dashboard for isolating any workload (filters by `namespace`, `container`, `stream`).
- **Backstage integration**: should link to **Kubernetes Loki logs** for workload log access.

## Collector configuration (validated at runtime)
- Fluent Bit config in CM `observability/fluent-bit` matches repo: tail input, Kubernetes filter (Merge_Log On, Keep_Log Off), Lua filter, Loki output.
- Lua script `remove_labels` removes high-cardinality labels and **drops `default` namespace** entirely.
- Loki output uses nested accessors for labels: `namespace`, `container`, `pod`, `stream`.

## Runtime state (validated)
- Loki Service resolves and `/ready` returns 200 from within cluster.
- Loki labels present: `namespace`, `container`, `pod`, `stream`, `job`, `service_name`.
- `stream` includes `stdout`/`stderr`.

## Log formatting reality (non-Backstage)
- Not all workloads emit JSON.
  - `argocd` and `kube-system` (Cilium) logs are key=value lines.

## Dashboard rendering behavior
- *Kubernetes Loki logs* uses a plain selector and regex filter; it renders **raw log lines**.
- Fluent Bit removes metadata keys but does not normalize the log body, so JSON logs show full JSON and key=value logs show full key=value.

## Optional improvement (design decision pending)
- **Normalize JSON at collector**: parse JSON logs, extract a message field, and emit clean `log` while preserving structured fields as metadata.
  - Requires a consistent JSON schema (`msg`/`message` key choice) across workloads.

## Known exclusions
- Backstage JSON logging is excluded (no Helm toggle; would require code change).