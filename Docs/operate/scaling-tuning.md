---
# Scaling & Tuning — Knobs that actually move the needle

Make capacity intentional: prioritize what must stay up, keep metrics/logs affordable, and avoid cardinality explosions.

## Prioridades y pools (sin diagrama)

- Infra / Policy / Observ corren en nodos de infra.
- CICD y Dash en nodos de workload (excepto control plane como lifeboat).
- Cada `values.yaml` debe definir `priorityClassName`; Kyverno lo valida.

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
