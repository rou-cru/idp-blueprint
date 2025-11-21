# Observability stack — component view

The observability stack covers metrics, logs, and dashboards with minimal footprint. It lives under `K8s/observability/` and is powered by Prometheus, Loki, Fluent-bit, and Grafana.

This page is the component view for the “Observability” part of the developer‑facing stacks.

## Components at a Glance

| Component | Deploy Path | Purpose |
| --- | --- | --- |
| Prometheus | `K8s/observability/kube-prometheus-stack/` | Scrapes cluster + workload metrics, exposes Alertmanager + Grafana. |
| Fluent-bit | `K8s/observability/fluent-bit/` | Tails container logs on every node and forwards to Loki. |
| Loki | `K8s/observability/loki/` | Stores logs in boltDB shipper mode (single replica for k3d). |
| Grafana | Bundled via Prometheus stack | Serves dashboards, integrates with Prometheus + Loki datasources automatically. |

### Repo wiring & tasks

- ApplicationSet: `K8s/observability/applicationset-observability.yaml` watches `K8s/observability/*`.
- Deploy only observability stack: `task stacks:observability`.
- Grafana admin credentials are synced from Vault via `ExternalSecret` (see `kube-prometheus-stack/grafana-admin-externalsecret.yaml`).

## Data Flow

```d2
direction: right

classes: { infra: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           data: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
           ui: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white } }

Nodes: {
  class: infra
  Pods: "Workload pods"
  Fluent: "Fluent-bit DaemonSet"
  NodeExp: "Node Exporter"
  Kubelet: "Kubelet"
  cAdvisor: "cAdvisor"
  KSM: "Kube-State-Metrics"
}

Observability: {
  class: data
  Prom: "Prometheus Operator"
  Loki: "Loki"
  Alert: "Alertmanager"
}

UX: {
  class: ui
  Grafana: "Grafana"
  Pyrra: "Pyrra (SLOs)"
}

Nodes.Pods -> Nodes.Fluent: "Logs"
Nodes.Fluent -> Observability.Loki: "push"
Nodes.Pods -> Observability.Prom: "app metrics"
Nodes.NodeExp -> Observability.Prom: "node metrics"
Nodes.Kubelet -> Observability.Prom: "kubelet metrics"
Nodes.cAdvisor -> Observability.Prom: "cAdvisor"
Nodes.KSM -> Observability.Prom: "cluster metrics"
Observability.Prom -> Observability.Alert: "alerts"
Observability.Prom -> UX.Grafana: "datasource"
Observability.Loki -> UX.Grafana: "logs datasource"
UX.Pyrra -> Observability.Prom: "reads SLO burn rates"
```

## Instrumentation Strategy

1. **ServiceMonitors everywhere** – Each stack component (ArgoCD, Kyverno, Trivy, etc.) exposes metrics and is annotated with the `prometheus: kube-prometheus` label so the Prometheus Operator scrapes it automatically.
2. **Common labels** – `app.kubernetes.io/*` labels ensure dashboards can group data by stack or owner (ties into FinOps tagging).
3. **Lightweight retention** – Prometheus stores ~2 days of data; Loki uses boltdb-shipper with 5Gi PVC to stay laptop-friendly. Adjust in `kube-prometheus-stack-values.yaml` and `loki-values.yaml` if you need longer retention.
4. **Dashboards bundled** – Grafana sidecars import dashboards located in `K8s/observability/kube-prometheus-stack/dashboards/`. Add JSON there to keep everything GitOps-managed.

## Alerting

The Prometheus stack enables Alertmanager but does not send notifications by default. To enable alerts:

1. Create a `Secret` named `alertmanager-kube-prometheus-stack-alertmanager` with your receiver configuration.
2. Update `alertmanager.config` in `kube-prometheus-stack-values.yaml` to reference the secret or inline config.
3. Commit and let ArgoCD roll out the change.

### Verify

- Grafana UI: `https://grafana.<ip-dashed>.nip.io` via Gateway
- Prometheus targets: check `Status → Targets` and confirm `kubernetes-apiservers`, `node-exporter`, etc.
- Loki logs: Explore → Loki → `{namespace="observability"}` to see stack logs

## Custom Dashboards Workflow

- Platform engineer adds/updates JSON under `K8s/observability/kube-prometheus-stack/dashboards/`.
- Commit → ApplicationSet syncs → Grafana sidecar reloads dashboards.
- Verify in Grafana UI. No separate diagram needed.

## Extending the Stack

- **Add Tempo/OTel**: Create `K8s/observability/tempo/` with a Helm chart entry and reference it from the ApplicationSet.
- **Per-team dashboards**: Use folder provisioning and `grafana.dashboards` values to organize by stack (`observability`, `cicd`, etc.).
- **Metrics federation**: Enable the Prometheus `federation` job in values if sending data to an external monitoring plane.
