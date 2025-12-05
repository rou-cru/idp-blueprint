---
title: Observability stack — component view
sidebar:
  label: Observability
  order: 6
---

The observability stack covers metrics, logs, and dashboards with minimal footprint.
It lives under `K8s/observability/` and is powered by Prometheus, Loki, Fluent-bit,
and Grafana.

This page is the component view for the "Observability" part of the
developer‑facing stacks.

## Components at a Glance

| Component | Deploy Path | Purpose |
| --- | --- | --- |
| Prometheus | `K8s/observability/kube-prometheus-stack/` | Metrics; AM + Grafana. |
| Fluent-bit | `K8s/observability/fluent-bit/` | Tails node logs and forwards to Loki. |
| Loki | `K8s/observability/loki/` | Logs in boltdb-shipper mode (single replica). |
| Pyrra | `K8s/observability/pyrra/` | SLO management with Prometheus. |

![Pyrra UI Placeholder](../../../assets/images/pyrra-ui.png)
| Grafana | Bundled via Prometheus stack | Dashboards; auto-wired to Prometheus + Loki. |

### Repo wiring & tasks

The ApplicationSet in `K8s/observability/applicationset-observability.yaml` watches
`K8s/observability/*`. Deploy only the stack with `task stacks:observability`.
Grafana admin credentials are synced from Vault via `ExternalSecret`
(`kube-prometheus-stack/grafana-admin-externalsecret.yaml`).

![Grafana UI Placeholder](../../../assets/images/grafana-ui.png)

## Data Flow

![Observability Data Flow](../assets/diagrams/architecture/observability-dataflow.svg)

## Instrumentation Strategy

Each component (ArgoCD, Kyverno, Trivy, etc.) exposes metrics via ServiceMonitors
annotated `prometheus: kube-prometheus` so the operator scrapes them. Common
`app.kubernetes.io/*` labels let dashboards group by stack/owner for FinOps.
Prometheus keeps ~2 days; Loki uses boltdb-shipper with 5Gi PVC (tune in
`kube-prometheus-stack-values.yaml` and `loki-values.yaml`). Grafana sidecars import
dashboards from `K8s/observability/kube-prometheus-stack/dashboards/`, keeping it
GitOps-managed.

## Alerting

Alertmanager is enabled but sends nothing by default. To enable alerts, create a
`Secret` named `alertmanager-kube-prometheus-stack-alertmanager` with your receiver
config, update `alertmanager.config` in `kube-prometheus-stack-values.yaml` to reference
the secret or inline config, and commit so ArgoCD rolls out the change.

### Verify

- Grafana UI: `https://grafana.<ip-dashed>.nip.io` via Gateway
- Prometheus targets: `Status → Targets`; confirm `kubernetes-apiservers`, `node-exporter`.
- Loki logs: Explore → Loki → `{namespace="observability"}` to see stack logs

## Custom Dashboards Workflow

Platform engineers add or update JSON under
`K8s/observability/kube-prometheus-stack/dashboards/`. After committing, the
ApplicationSet syncs and the Grafana sidecar reloads dashboards automatically.
Verify changes in the Grafana UI.

## Extending the Stack

- **Add Tempo/OTel**: Create `K8s/observability/tempo/` and add to the ApplicationSet.
- **Per-team dashboards**: Folder provisioning + `grafana.dashboards` to group by stack.
- **Metrics federation**: Enable the Prometheus `federation` job to export outward.
