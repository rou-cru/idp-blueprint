---
title: Adding a New Component
sidebar:
  label: Add Component
  order: 5
---
---


Treat every component as code. Adding, changing, or removing should feel like a small, reviewable PR.

## The recipe (concise)

1. Crea `K8s/<stack>/<name>/`.
2. Define `kustomization.yaml` (recursos o `helmCharts`).
3. Aplica etiquetas canónicas (`owner`, `business-unit`, `environment`, `app.kubernetes.io/*`).
4. Commit + push.
5. ApplicationSet detecta la carpeta → ArgoCD crea `Application`.
6. Sync respeta waves/policies y converge en el cluster.

Steps:

- Create a folder under the right stack (for example `K8s/observability/<name>`).
- Add a Kustomize overlay; optionally use `helmCharts` with a `*-values.yaml`.
- Apply canonical labels; set `priorityClassName` and reasonable `resources`.
- Commit and push; the ApplicationSet generates the Application.

Tips:

- Prefer sync waves and explicit dependencies when components interact.
- Add a `ServiceMonitor` with label `prometheus: kube-prometheus`.
- Expose UI via Gateway with an `HTTPRoute` if relevant.

## Governance overlay pattern

Every stack ships with a `governance/` folder that is synced ahead of the workloads. It contains the namespace definition plus the mandatory `LimitRange` and `ResourceQuota` for that stack (`argocd.argoproj.io/sync-wave` keeps the order deterministic). Copy the pattern from any existing stack such as `K8s/events/governance/*` or `K8s/cicd/governance/*`:

1. `namespace.yaml` — canonical labels (`app.kubernetes.io/part-of`, `owner`, `business-unit`, `environment`) and sync wave `-2`.
2. `limitrange.yaml` — guardrails for default requests/limits sized for the stack.
3. `resourcequota.yaml` — hard ceilings to keep noisy neighbors in check.

This overlay is part of the platform contract (“Namespace governance” in [Contracts & Guardrails](contracts.md)); omitting it will fail reviews and breaks capacity planning.
