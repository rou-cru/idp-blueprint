---
title: FinOps Tagging & Cost Attribution
sidebar:
  label: FinOps Tags
  order: 6
---

The platform front-loads tagging so you can attribute resource usage—even on a laptop demo—
before you grow into cloud cost tools.

## Tagging Stack

| Layer | Mechanism | Purpose |
| --- | --- | --- |
| Git defaults | `namespace.yaml` + `kustomization.yaml` | Bake labels into manifests. |
| Kyverno enforcement | `Policies/rules/baseline/*.yaml` | Patch/deny if tags are missing. |
| Observability labels | Prom + Fluent Bit relabel | Push tags into metrics/logs. |
| Export targets | Cloud billing or Kubecost | Reuse the same labels for spend views. |

## Label to FinOps Mapping

| Label | Question Answered | Example Use |
| --- | --- | --- |
| `owner` | Who runs this stack? | Show per-team spend charts. |
| `business-unit` | Which budget funds it? | Tie infra usage to a BU. |
| `environment` | Lifecycle stage? | Separate demo from production noise. |
| `app.kubernetes.io/component` | Which workload? | Compare GitOps vs CI/CD costs. |
| `app.kubernetes.io/part-of` | Which platform? | Filter multi-tenant clusters. |

## Flow from Labels to Dashboards

![FinOps Tags Flow](../assets/diagrams/reference/finops-tags-flow.svg)

> **Source:** [finops-tags-flow.d2](../assets/diagrams/reference/finops-tags-flow.d2)

## Best Practices

1. **Validate locally** using `Scripts/validate-consistency.sh`; it flags missing labels.
2. **Propagate to external tools** by mapping labels to `kubecost.cloud.google.com/team`
   (or similar) via relabeling when you export metrics.
3. **Document exceptions**: if a workload truly cannot carry certain labels, add a
   Kyverno `exclude` block and explain it in the PR.
