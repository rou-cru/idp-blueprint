# Security Stack — Trivy Operator + Policy Reporter (validated 2025-12-27)

## Trivy Operator (repo + cluster)
- Stack location: `K8s/security/trivy/` (AppSet under `K8s/security/`).
- Deployment: `trivy-operator` (Deployment) + `trivy-server` (StatefulSet) in namespace `security`.
- Mode: ClientServer with built-in Trivy Server enabled.
- Scanning scope: target workloads `replicaset,statefulset,daemonset,cronjob` (pods excluded); excluded namespaces include `kube-system,argocd,cert-manager,vault-system,kyverno-system`.
- Compliance: `k8s-pss-baseline-0.1` enabled; vulnerability severity `HIGH,CRITICAL`.
- ServiceMonitor: `trivy-operator` exists in `security` namespace.

## Policy Reporter (repo + cluster)
- Deployed via `K8s/policies/infrastructure/policy-reporter/` into `kyverno-system`.
- REST API enabled; UI disabled (headless).
- Prometheus metrics enabled; ServiceMonitor in `kyverno-system` (`policy-reporter-monitoring`).
- Grafana dashboards are created as ConfigMaps in `kyverno-system` with label `grafana_dashboard=1`:
  - `policy-reporter-monitoring-*` dashboards (3 CM).
- Backstage proxy and baseUrl point to Policy Reporter service (`/policy-reporter`).

## Kyverno (cluster)
- Controllers running in `kyverno-system` (admission/background/cleanup/reports).
- ServiceMonitor present for `kyverno-admission-controller`.

## Grafana dashboards (cluster)
- Kyverno dashboard present: UID `Rg8lWBG7k`.
- Trivy dashboards present: `Trivy Operator Dashboard` (UID `ycwPj724k`), `Trivy Image Vulnerability Overview` (UID `4SECJjm4z`).
- Policy Reporter dashboards **not visible** in Grafana search (despite ConfigMaps), indicating sidecar/label or provisioning mismatch to investigate.

## Metrics check (cluster)
- No `policy_reporter_*` metrics currently visible in Prometheus query results (needs validation of ServiceMonitor + labels/targets).