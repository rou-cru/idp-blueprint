---
title: Policies & governance — Kyverno + Policy Reporter
sidebar:
  label: Policies
  order: 5
---

Governance lives under `Policies/` and is deployed before any workload stacks sync. Kyverno enforces the rules, while Policy Reporter surfaces compliance status.

This page shows the component view for the automation & governance layer (Kyverno + Policy Reporter).

## Policy Layers

| Layer | Location | Purpose |
| --- | --- | --- |
| Baseline (namespaces, labels) | `Policies/rules/baseline/` | Ensures namespaces + workloads receive canonical labels, quotas, and annotations. |
| Security safeguards | `Policies/rules/security/` | Blocks privileged pods, enforces read-only root FS, validates image registries. |
| Platform hygiene | `Policies/rules/platform/` | Checks ServiceAccount usage, requires requests/limits, and validates priority classes. |

## Deployment Path

```d2
direction: right

classes: { actor: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           git: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           data: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
           ui: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white } }

Author: { class: actor; label: "Platform Engineer" }
Repo: { class: git; label: "Policies/ (Git)\nKyverno + Reporter" }
Argo: { class: control; label: "ArgoCD\nPolicies App" }
Kyverno: { class: control; label: "Kyverno controllers" }
Cluster: { class: data; label: "Namespaces + workloads" }
Reporter: { class: ui; label: "Policy Reporter UI\n+ metrics to Grafana" }

Author -> Repo: "edit / review"
Repo -> Argo: "commit → sync"
Argo -> Kyverno: "apply manifests"
Kyverno -> Cluster: "enforce / mutate / audit"
Kyverno -> Reporter: "PolicyReports"
Reporter -> Author: "dashboards & alerts"
```

- `Policies/app-kyverno.yaml` – ArgoCD Application applied during bootstrap.
- `Policies/kustomization.yaml` – Installs both the Kyverno Helm release and all policy manifests.
- `Policies/policy-reporter/` – Deploys Policy Reporter + UI for at-a-glance status.

### Repo wiring & tasks

- Bootstrap runs `task stacks:policies` after ArgoCD, applying `Policies/app-kyverno.yaml` with `REPO_URL`/`TARGET_REVISION` envsubst.
- To redeploy policies only: `task stacks:policies`.
- Lint/check before pushing: `task quality:lint` and `task quality:check`.

## Sync Waves & Priority

Kyverno policies plug into the same sync‑wave model described in
[`GitOps, Policy, and Eventing`](../concepts/gitops-model.md).

| Resource | Sync Wave | Notes |
| --- | --- | --- |
| Kyverno Namespace/RBAC | `-2` | Must exist before CRDs/webhooks. |
| Kyverno Helm Release | `-1` | Installs CRDs + controllers. |
| ClusterPolicies | `0` | Apply after controllers are ready. |
| Policy Reporter | `1` | Consumes policy reports after Kyverno starts emitting them. |

## Policy lifecycle

```d2
direction: right

classes: { actor: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           gov: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           ui: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
           domain: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Lifecycle: {
  class: gov
  label: "Policy lifecycle"
  Repo: "Git: Policies/"
  Argo: "ArgoCD policy app"
  Kyverno: "Kyverno controllers"
  Cluster: {
    class: domain
    label: "Cluster scope"
    Work: "Workloads"
    Ns: "Namespaces"
  }
Reporter: {
  class: ui
  label: "Reporting UI"
  PR: "Policy Reporter"
  Grafana: "Grafana (dashboards)"
}
}

Author: { class: actor; label: "Engineer" }

Author -> Lifecycle.Repo: "author / review"
Lifecycle.Repo -> Lifecycle.Argo: "commit → sync"
Lifecycle.Argo -> Lifecycle.Kyverno: "apply"
Lifecycle.Kyverno -> Lifecycle.Cluster.Work: "mutate/enforce"
Lifecycle.Kyverno -> Lifecycle.Cluster.Ns: "validate labels"
Lifecycle.Kyverno -> Lifecycle.Reporter.PR: "PolicyReports"
Lifecycle.Reporter.PR -> Lifecycle.Reporter.Grafana: "dashboards/metrics"
Lifecycle.Reporter.Grafana -> Author: "status + alerts"
```

### Verify

- Kyverno ready: `kubectl -n kyverno-system get deploy kyverno-admission-controller`
- Reporter UI: check Service/Ingress in `kyverno-system` and the dashboards
- Policy reports: `kubectl get policyreport,clusterpolicyreport -A`

## Writing Good Policies

1. **Stay declarative** – target labels and annotations (from the label standard) instead of naming individual workloads.
2. **Test locally** – use `kyverno apply` or `kyverno test` against manifests before pushing.
3. **Annotate severity** – add `policies.kyverno.io/severity` so Policy Reporter can filter.
4. **Document remediation** – set `policies.kyverno.io/description` and `documentation` annotations so the UI links back to internal runbooks.

### Local tests

- `kyverno apply` on a manifest to see allow/deny
- `kyverno test` on a curated set of cases under a `tests/` folder (optional pattern)

## Policy Reporter Dashboards

Policy Reporter exposes a UI (and Prometheus metrics) with:

- **Policy compliance score** by namespace or application.
- **Top failing policies** to highlight drift or missing labels.
- **Audit history** for previously non-compliant resources.

Hook Grafana into the Policy Reporter metrics endpoint to correlate policy drift with deployments or cost spikes.
