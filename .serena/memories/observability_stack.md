# Observability Stack (validated 2025-12-04)

- AppSet: `K8s/observability/applicationset-observability.yaml`; project `observability`; discovers `K8s/observability/*`; syncPolicy with SSA/PruneLast/ApplyOutOfSyncOnly/RespectIgnoreDifferences; retry 10; extra ignoreDifferences for pyrra SLO status. Fuse: `fuses.observability` (task `stacks:observability`).
- Namespace/governance: `K8s/observability/governance` (namespace sync-wave -2, limitrange, resourcequota). Priority classes used: platform-observability for most pods, platform-dashboards for Grafana.
- Secrets: SecretStore `observability` (Vault HTTP demo URL, role `eso-observability-role`, sync-wave -1) + SA `external-secrets` (`K8s/observability/infrastructure`). ExternalSecret `grafana-admin-credentials` (refresh 3m, template admin-user=admin, password from Vault `secret/grafana/admin`).
- Components:
  - **kube-prometheus-stack** (`kustomization.yaml`): Helm chart values with Grafana persistence 1Gi, admin creds from ExternalSecret, additional datasource Loki at `http://loki.observability.svc.cluster.local:3100`, plugins piechart/polystat/json; Prometheus Operator webhooks via cert-manager (ca-issuer), priorityClass platform-observability.
  - **Loki** (`loki/values.yaml`): singleBinary, filesystem storage, retention 6h, persistence 2Gi, resources 100m/512Mi req, 500m/1Gi limits, gateway disabled.
  - **Fluent Bit** (`fluent-bit/values.yaml`): DaemonSet, logs tail + kubernetes filter + Lua filter to drop high-card labels; resources 50m/64Mi req, 100m/128Mi limits; metrics port 2020.
  - **Pyrra** (`pyrra/kustomization.yaml`, `values.yaml`): Helm chart 0.19.2 with ServiceMonitor enabled; sync-wave 2; priorityClass platform-observability.
  - **SLOs** (`slo/*.yaml`): Pyrra SLOs for externalsecrets sync, gateway availability, loki ingest, vault API.
- Ingress/HTTPRoutes: Grafana exposed via Gateway HTTPRoute `IT/gateway/httproutes/grafana-httproute.yaml` (hostname `grafana.${DNS_SUFFIX}`); Pyrra via `pyrra-httproute.yaml`; Loki not exposed (service ClusterIP).
- Credentials: Grafana admin user `admin`, password from Vault secret path `secret/grafana/admin` property `admin-password` (populated by `task vault:generate-secrets`).
- Storage: All components use in-cluster PVCs (Grafana 1Gi, Loki 2Gi). Prometheus uses chart defaults (adjust if needed).
- k3d/k3s nuance: `IT/k3d-cluster.yaml` adds kube-scheduler/controller-manager/kube-proxy metrics bind-address=0.0.0.0 so Prometheus Operator can scrape control-plane endpoints; keep these args or you will miss control-plane metrics on k3s/k3d. Without them, metrics ports bind to localhost only (upstream k8s defaults differ).