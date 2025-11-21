---

# Contracts & Guardrails — What keeps the IDP coherent

This page lists every platform contract: what it is, its type, where it lives in Git, how it’s enforced, and what breaks if you violate it.

## GitOps Source (repo / revision)

- Type: API/config between Tasks → ArgoCD ApplicationSets
- Lives: `config.toml [git]`, `Taskfile.yaml (REPO_URL/TARGET_REVISION)`, ApplicationSets (`envsubst`)
- Enforcement: n/a (observed via ArgoCD UI)
- Failure: wrong repo/branch → no sync

## Labels & Metadata (FinOps / ownership)

- Type: data schema on Namespace + workloads
- Lives: Kyverno `enforce-namespace-labels`, `require-component-labels` (audit)
- Enforcement: Kyverno (namespace: enforce; components: audit)
- Failure: cost attribution/selection breaks; future policies won’t match

## Prometheus selection (metrics)

- Type: label-based ingest contract
- Lives: Prometheus `serviceMonitorSelector/podMonitorSelector` = `prometheus=kube-prometheus`
- Enforcement: Prom Operator selectors
- Failure: ServiceMonitor without label → never scraped

## Grafana dashboards discovery

- Type: config discovery via label
- Lives: Grafana sidecar `dashboards.label = grafana_dashboard`
- Enforcement: sidecar importer
- Failure: ConfigMap without label → not visible in UI

## Gateway routes (public endpoints)

- Type: hostname→Service mapping
- Lives: HTTPRoutes (`IT/gateway/httproutes/*`), `DNS_SUFFIX` from `config.toml`
- Enforcement: Gateway API controller
- Failure: Service renames break routes; nip.io depends on correct LAN IP

## Secrets flow (Vault → ESO → K8s Secret)

- Type: access/data and update policy
- Lives: ExternalSecret manifests; `creationPolicy: Merge` for charts that write keys
- Enforcement: ESO controller; (optionally) Kyverno to require `Merge` on critical Secrets
- Failure: wrong path → stale secrets; no Merge → charts overwrite or lose fields

## Priority & Scheduling

- Type: operational contract (every workload declares `priorityClassName`)
- Lives: PriorityClasses under `IT/priorityclasses/`; coverage script
- Enforcement: CI check script; (optional) Kyverno to require priority on workload kinds
- Failure: critical planes preempted under pressure

## Namespace governance (limits/quotas)

- Type: operational guardrail
- Lives: `K8s/*/governance/{limitrange,resourcequota}.yaml`
- Enforcement: Kubernetes admission
- Failure: noisy neighbors; unbounded resources

## Folder → Application (ApplicationSets)

- Type: structural convention (generator)
- Lives: `K8s/*/applicationset-*.yaml` maps `K8s/<stack>/*` → Applications
- Enforcement: ArgoCD ApplicationSet controller
- Failure: wrong folder → wrong namespace/project

## CRDs first, then CRs (ordering)

- Type: installation order
- Lives: `Task/bootstrap.yaml it:apply-crds` before stacks
- Enforcement: Tasks do it in order
- Failure: CRs rejected (no CRD)

## Helm repositories (supply)

- Type: dependency mapping for charts
- Lives: `IT/argocd/values.yaml` → `configs.repositories`
- Enforcement: ArgoCD uses them for chart lookup
- Failure: sync failures with “chart not found”

## Admin credential flow (ArgoCD)

- Type: security contract (Vault is source of truth)
- Lives: `config.toml [passwords]` (empty→random), `vault-generate.sh`, ExternalSecret to `argocd-secret`
- Enforcement: ESO + Vault
- Failure: weak defaults if set; race avoided by Merge

## Observability Rules (SLOs & Alerts)

- Type: behavior contract (SLOs as code)
- Lives: `K8s/observability/slo/*.yaml` (Pyrra);
- Enforcement: Pyrra → PrometheusRule → Alertmanager
- Failure: wrong metrics/labels → SLOs don’t compute or alert

## Eventing

- Type: event schema + routing contract
- Lives: `K8s/events/*` (governance, sources, sensors, triggers)
- Enforcement: Argo Events controllers
- Failure: webhooks misrouted; triggers not firing

## Contract meta checklist

- Validations: `Scripts/validate-consistency.sh` (labels, priority coverage, deprecated APIs)
- Profiles/Fuses: `config.toml [fuses]` toggle stacks and prod hardening
- Cluster name: `config.toml [cluster] name` used by k3d and Cilium

Keep this page updated when introducing new stacks or toggles. Every new capability needs an explicit, documented contract.
