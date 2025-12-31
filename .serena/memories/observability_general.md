# Observability Stack — General (validated 2025-12-27)

## Components (cluster)
Namespace `observability`:
- Prometheus: `prometheus-prometheus-kube-prometheus-prometheus` (StatefulSet).
- Alertmanager: `alertmanager-prometheus-kube-prometheus-alertmanager` (StatefulSet).
- Grafana: `prometheus-grafana` (Deployment).
- Loki: `loki` (StatefulSet, SingleBinary).
- Fluent Bit: `fluent-bit` (DaemonSet).
- Pyrra: `pyrra` (Deployment).
- kube-state-metrics + node-exporter present.

## Prometheus (repo + cluster)
- Helm chart: `K8s/observability/kube-prometheus-stack`.
- ServiceMonitor/PodMonitor selectors are **empty** (select all namespaces).
- Global scrape interval 60s, timeout 40s.
- Retention **24h** (matches Prometheus CR runtime).
- Storage: PVC 1Gi.

## Alertmanager (repo)
- Enabled with JSON logging, low resource limits.
- Config routes to Argo Events webhook:
  - `http://alertmanager-eventsource-svc.argo-events.svc.cluster.local:12000/webhook`.

## Grafana (repo + cluster)
- Admin credentials sourced from ESO (`grafana-admin-credentials`).
- Datasources in Grafana (cluster): `Prometheus` (default), `Loki`, `Alertmanager`.
- Dashboards loaded from:
  - gnet IDs in `kube-prometheus-stack/values.yaml`.
  - Sidecar discovery of ConfigMaps labeled `grafana_dashboard`.
- Allow embedding enabled in `grafana.ini` (used by Backstage).

## Loki + Fluent Bit (repo + cluster)
- Loki: SingleBinary, filesystem storage, 24h retention, 2Gi PVC.
- Fluent Bit outputs to Loki; labels include `namespace`, `container`, `pod`, `stream`, `app`.
- Default namespace logs are dropped by Lua filter.

## ServiceMonitors (cluster)
Prometheus scrapes across namespaces including:
- Cilium/Hubble (kube-system), Kyverno/Policy Reporter (kyverno-system), External Secrets, Cert‑Manager, Trivy Operator, Vault, ArgoCD, Argo Events, and all observability components.

## Dashboards confirmed in Grafana (cluster)
- Logs: Container Log Dashboard (`fRIvzUZMz`), Kubernetes Logs from Loki (`ae3ec2c4-...`), Loki Logging Volume Analysis (`nmSpiZwHz`).
- SRE/SLO: Pyrra dashboards (`YuUMRZ44z`, `ccssRIenz`).
- Security: Kyverno (`Rg8lWBG7k`), Trivy dashboards (`ycwPj724k`, `4SECJjm4z`).

## Notes
- SLO definitions and status are tracked in `sre_slo_state` memory.
- Policy Reporter dashboards exist as ConfigMaps but are not visible in Grafana search (investigate sidecar/label/provisioning if needed).