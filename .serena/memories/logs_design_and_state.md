# Logs Pipeline — Design + Runtime State (validated 2025-12-27)

## Architecture (repo)
- Pipeline: Fluent Bit (DaemonSet) → Loki → Grafana.
- GitOps stack: Observability ApplicationSet (`K8s/observability/applicationset-observability.yaml`).
- Loki: **SingleBinary** mode with filesystem storage and 24h retention (`K8s/observability/loki/values.yaml`).
- Grafana datasource for Loki defined in `K8s/observability/kube-prometheus-stack/values.yaml` with `uid: Loki`.

## Fluent Bit output + labels (repo)
- Loki output uses nested label mapping:
  - `namespace`, `container`, `pod`, `stream`, `app` (from `app.kubernetes.io/name`).
- Output formatting:
  - `line_format key_value`, `drop_single_key true`, `remove_keys kubernetes,stream,filename,time,_p`.
- Lua filter drops high‑cardinality labels and **drops the `default` namespace** entirely.

## Loki runtime (cluster)
- `/ready` returns `ready` from inside the pod.
- Labels available in Loki:
  - `app`, `container`, `namespace`, `pod`, `service_name`, `stream`.
- Namespaces present in Loki (sample):
  - `argo-events`, `argocd`, `backstage`, `cert-manager`, `external-secrets-system`, `kube-system`, `kyverno-system`, `observability`, `security`, `vault-system`.

## Grafana log dashboards present (cluster)
- **Container Log Dashboard** (UID `fRIvzUZMz`, gnetId 16966).
- **Kubernetes Logs from Loki** (UID `ae3ec2c4-1c19-4450-9403-226270fe0c4f`, gnetId 18494).
- **Loki Logging Volume Analysis** (UID `nmSpiZwHz`, gnetId 23789).
- **Logs by Namespace** (gnetId 19566).

## Known removals
- UIDs `o6-BGgnnk` and `NClZGd6nA` are **not present** in Grafana and should not be referenced.