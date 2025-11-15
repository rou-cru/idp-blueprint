# GitOps, Policy, and Eventing — The Control Backbone

This IDP is GitOps‑first, policy‑driven, and event‑oriented. The goal is one predictable path from intent to action, plus a programmable way to react to signals.

## Two layers of change: Bootstrap vs GitOps

- Bootstrap (`IT/`): one‑time installation for control planes and base services (Cilium, cert‑manager, Vault/ESO, ArgoCD, Gateway). It’s code, but not continuously reconciled.
- GitOps (`K8s/`): continuously reconciled state. ApplicationSets watch directories and generate Applications.

```d2
direction: right

IT: "Bootstrap (once)"
K8s: "GitOps (continuous)"
IT -> K8s: "seed control planes"
```

## AppProjects and ApplicationSets — guardrails and generation

- AppProjects define blast radius (source repos + destinations). See `IT/argocd/appproject-*.yaml`.
- ApplicationSets map folders → Applications. One commit = one rollout.

```d2
direction: right

Git: {
  Repo: "${REPO_URL} @ ${TARGET_REVISION}"
  Folders: {
    Obs: "K8s/observability/*"
    Cicd: "K8s/cicd/*"
    Sec: "K8s/security/*"
  }
}

ArgoCD: {
  AppProjects
  ApplicationSets
  Applications
}

Git.Folders.Obs -> ArgoCD.ApplicationSets: "generator"
ArgoCD.ApplicationSets -> ArgoCD.Applications: "templates"
ArgoCD.Applications -> Cluster: "sync (waves)"
```

## Policy — turning conventions into guarantees

Kyverno validates at admission (and can mutate/generate). Use it to encode platform rules so every namespace and workload ships with the right labels, limits, and safety constraints.

Examples to enforce:
- Namespace labels (owner, business-unit, environment).
- Component labels on Deployments/StatefulSets/DaemonSets.
- Default NetworkPolicies (planned hardening). 

## Eventing — a programmable nervous system (planned core)

Argo Events makes “what happens next” explicit: route events into Sensors, then trigger Workflows, ArgoCD actions, or HTTP calls. Treat alerts, GitHub webhooks, and K8s resource state changes the same: as events.

Typical recipes:
- SLO burn → rollback → notify.
- GitHub PR → build+test → preview.
- ArgoCD OutOfSync → refresh/sync → gate on policy.

```d2
direction: right

Sources: {
  label: "Event Sources"
  Alertmanager
  GitHub
  K8sResources
}

ArgoEvents: {
  Sensors: "filters + routing"
  Triggers: {
    WF: "Argo Workflows"
    ACD: "ArgoCD API"
    HTTP: "Webhooks"
  }
}

Sources -> ArgoEvents.Sensors: emit
ArgoEvents.Sensors -> Triggers.WF
ArgoEvents.Sensors -> Triggers.ACD
ArgoEvents.Sensors -> Triggers.HTTP
```

## Sync policy, drift, and safety

- Automated prune + self‑heal keep the cluster aligned with Git.
- Server‑side apply and out‑of‑sync only reduce noisy diffs.
- Ignore non‑deterministic fields (e.g., webhook caBundle) to avoid drift noise.

## Secrets in the loop (conceptual)

ESO authenticates to Vault and writes K8s Secrets. Workloads consume only K8s Secrets. Use `creationPolicy: Merge` when charts need to add internal keys later.

![ArgoCD apps](../assets/images/after-deploy/argocd-apps-healthy.jpg){ loading=lazy }
