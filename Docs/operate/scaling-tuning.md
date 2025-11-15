---
# Scaling & Tuning — Knobs that actually move the needle

Make capacity intentional: prioritize what must stay up, keep metrics/logs affordable, and avoid cardinality explosions.

## Priorities and pools

```d2
direction: right

Priority: {
  Infra: "platform-infrastructure"
  Policy: "platform-policy"
  Observ: "platform-observability"
  CICD: "platform-cicd / cicd-execution"
  Dash: "platform-dashboards"
}

Nodes: {
  Control: "control plane"
  Infra: "infra nodes"
  Work: "workload nodes"
}

Priority.Infra -> Nodes.Infra
Priority.Policy -> Nodes.Infra
Priority.Observ -> Nodes.Infra
Priority.Dash -> Nodes.Work
Priority.CICD -> Nodes.Work
```

Rules of thumb:
- Every values file sets `priorityClassName` (the repo checks for this).
- Keep DaemonSets lean; they run everywhere (Cilium, Fluent‑bit, Node Exporter).

## Observability knobs

- Prometheus: `retention`, TSDB storage, `scrapeInterval`, drop high‑card labels.
- Loki: pipeline stages, label hygiene, storage backends.
- Dashboards: render fast; prefer recording rules for expensive queries.

## Performance and safety

- Requests/limits tuned per component; quotas/limits per namespace.
- Backpressure: Fluent‑bit buffers; Loki ingestion limits.
- Avoid high cardinality metrics (pod UID, container ID) unless really needed.

## Cost & footprint

- Disable non‑critical components in dev/demo; scale up in staging/prod.
- FinOps labels are already enforced; use them to attribute and decide.
