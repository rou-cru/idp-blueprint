---
title: GitOps Model
sidebar:
  label: GitOps Model
  order: 2
---

> **Prerequisites:** This builds on the [GitOps philosophy](design-philosophy.md#3-gitops). For implementation details, see [Application Architecture](../architecture/applications.md).

This IDP is GitOps‑first, policy‑driven, and event‑oriented. The goal is one predictable path from intent to action, plus a programmable way to react to signals. We borrow C4 naming to structure views but keep diagrams jargon‑free.

## Two layers of change: Bootstrap vs GitOps

- Bootstrap (`IT/`): one‑time installation for control planes and base services (Cilium, cert‑manager, Vault/ESO, ArgoCD, Gateway). It’s code, but not continuously reconciled.
- GitOps (`K8s/`): continuously reconciled state. ApplicationSets watch directories and generate Applications.

```d2
direction: right

classes: { infra: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           gitops: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white } }

IT: { class: infra; label: "Bootstrap (IT/)\nOne-time install\nCilium, cert-manager, Vault, ESO, ArgoCD, Gateway" }
GitOps: { class: gitops; label: "GitOps (K8s/)\nContinuous reconcile\nStacks via ApplicationSets" }

IT -> GitOps: "seed control planes"
```

## AppProjects and ApplicationSets — guardrails and generation

- AppProjects define blast radius (source repos + destinations). See `IT/argocd/appproject-*.yaml`.
- ApplicationSets map folders → Applications. One commit = one rollout.

```d2
direction: right

classes: { git: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           ns: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Repo: { class: git; label: "Git\nK8s/* stacks" }

Argo: {
  class: control
  label: "ArgoCD"
  Projects: "AppProjects\n(blast radius)"
  AppSets: "ApplicationSets\n(one per stack)"
  Apps: "Applications\n(one per component)"
}

Namespaces: {
  class: ns
  OBS: "observability"
  CICD: "cicd"
  SEC: "security"
  DP: "backstage"
}

Repo -> Argo.AppSets: "directories → generators"
Argo.AppSets -> Argo.Projects: "scoped"
Argo.AppSets -> Argo.Apps: "templates"
Argo.Apps -> Namespaces.OBS: "sync"
Argo.Apps -> Namespaces.CICD
Argo.Apps -> Namespaces.SEC
Argo.Apps -> Namespaces.DP
```

## Sync Waves — ordering without scripts

ArgoCD applies resources in ascending `argocd.argoproj.io/sync-wave` order. This
lets you express dependencies declaratively instead of writing orchestration
scripts.

In this blueprint the main waves are:

- **-3** – bootstrap namespaces in `IT/namespaces/*.yaml` (cluster‑level
  infrastructure)
- **-2** – application/gov namespaces such as `K8s/*/governance/namespace.yaml`
- **-1** – SecretStores and other cluster prerequisites
- **0** – ExternalSecrets and most standard applications (default)
- **1** – governance objects like `LimitRange` and `ResourceQuota`
- **2** – Gateway and HTTPRoutes (expose services once backends are ready)
- **3** – SLO/UIs that depend on earlier layers (e.g. SLO dashboards)

Use negative waves for **foundations**, `0` as the common case, and positive
waves for **optional or edge‑exposed** resources.

## Policy — turning conventions into guarantees

Kyverno validates at admission (and can mutate/generate). Use it to encode platform rules so every namespace and workload ships with the right labels, limits, and safety constraints.

Examples to enforce:

- Namespace labels (owner, business-unit, environment).
- Component labels on Deployments/StatefulSets/DaemonSets.
- Default NetworkPolicies (planned hardening).

## Eventing — a programmable nervous system

Argo Events makes “what happens next” explicit: route events into Sensors, then trigger Workflows, ArgoCD actions, or HTTP calls. Treat alerts, GitHub webhooks, and K8s resource state changes the same: as events.

Typical recipes:

- SLO burn → rollback → notify.
- GitHub PR → build+test → preview.
- ArgoCD OutOfSync → refresh/sync → gate on policy.

```d2
direction: right

classes: { event: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           action: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Sources: {
  class: event
  Alert: "Alertmanager"
  GitHub: "GitHub webhooks"
  K8s: "K8s resource events"
}

Sensors: { class: control; label: "Argo Events Sensors\n(filters + routing)" }

Triggers: {
  class: action
  WF: "Argo Workflows"
  ACD: "ArgoCD API"
  HTTP: "HTTP/webhook"
}

Sources.Alert -> Sensors
Sources.GitHub -> Sensors
Sources.K8s -> Sensors
Sensors -> Triggers.WF
Sensors -> Triggers.ACD
Sensors -> Triggers.HTTP
```

## Sync policy, drift, and safety

- Automated prune + self‑heal keep the cluster aligned with Git.
- Server‑side apply and out‑of‑sync only reduce noisy diffs.
- Ignore non‑deterministic fields (e.g., webhook caBundle) to avoid drift noise.

## Secrets in the loop

ESO authenticates to Vault and writes K8s Secrets. Workloads consume only K8s Secrets. Use `creationPolicy: Merge` when charts need to add internal keys later.

![ArgoCD apps](../assets/images/after-deploy/argocd-apps-healthy.jpg){ loading=lazy }
