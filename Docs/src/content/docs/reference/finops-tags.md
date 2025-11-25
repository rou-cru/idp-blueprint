---
title: FinOps Tagging & Cost Attribution
sidebar:
  label: FinOps Tags
  order: 6
---

The platform front-loads tagging so you can attribute resource usage—even on a laptop demo—before expanding to cloud cost tools.

## Tagging Stack

| Layer | Mechanism | Purpose |
| --- | --- | --- |
| Git defaults | `namespace.yaml` + `kustomization.yaml` | Bake canonical labels into every resource. |
| Kyverno enforcement | `Policies/rules/baseline/*.yaml` | Patch/deny resources missing required tags. |
| Observability labels | Prometheus/Fluent-bit relabel configs | Propagate tags into metrics/logs for dashboards. |
| Export targets | Future cloud billing or Kubecost | Reuse the same labels for dollar allocation. |

## Label to FinOps Mapping

| Label | Question Answered | Example Use |
| --- | --- | --- |
| `owner` | Who runs this stack? | Show per-team spend charts. |
| `business-unit` | Which budget funds it? | Tie infra usage to BU budgets. |
| `environment` | Lifecycle stage? | Separate demo vs prod noise. |
| `app.kubernetes.io/component` | What workload type? | Compare cost across GitOps, observability, CI/CD. |
| `app.kubernetes.io/part-of` | Which platform? | Filter multi-tenant clusters. |

## Flow from Labels to Dashboards

```mermaid
flowchart LR
    Git[Git Labels] --> Kyverno[Kyverno Enforcement]
    Kyverno --> K8s[Kubernetes Resources]
    K8s --> Metrics[Prometheus Metrics]
    Metrics --> Grafana[Grafana Dashboards]
    Metrics --> Billing["FinOps Tool (Kubecost/Cloud)"]
```

## Best Practices

1. **Validate locally** using `Scripts/validate-consistency.sh` – it checks for missing labels.
2. **Propagate to external tools** by mapping labels to e.g., `kubecost.cloud.google.com/team` via relabeling if you export metrics.
3. **Document exceptions** – if a workload truly cannot carry certain labels, add a Kyverno `exclude` block and explain it in the PR.
