---
# Add or Change a Component — The safe GitOps way

Treat every component as code. Adding, changing, or removing should feel like a small, reviewable PR.

## The recipe

```d2
direction: right

Folder: "K8s/<stack>/<name>"
Overlay: "Kustomize + helmCharts (optional)"
Labels: "owner, business-unit, environment, app.kubernetes.io/*"
PR: "Commit & push"
Argo: "ApplicationSet → Application"
Cluster: "Sync (waves + policies)"

Folder -> Overlay -> Labels -> PR -> Argo -> Cluster
```

Steps:
- Create a folder under the right stack (for example `K8s/observability/<name>`).
- Add a Kustomize overlay; optionally use `helmCharts` with a `*-values.yaml`.
- Apply canonical labels; set `priorityClassName` and reasonable `resources`.
- Commit and push; the ApplicationSet generates the Application.

Tips:
- Prefer sync waves and explicit dependencies when components interact.
- Add a `ServiceMonitor` with label `prometheus: kube-prometheus`.
- Expose UI via Gateway with an `HTTPRoute` if relevant.

