---
# Concepts — the mental model of this IDP

This section explains how the main parts of the platform relate to each other so you can reason about changes and extend the IDP safely.

You will not find step‑by‑step setup here; that lives under Getting Started and Components. Instead, these pages define the product‑level concepts, loops, and contracts that make the whole system coherent.

## The IDP as a product

- A platform for developers, operated by platform engineers.
- A paved road: defaults that are secure, observable, and cost‑aware.
- One control backbone: declare in Git, reconcile to cluster, govern with policy, react to signals.

These concepts apply to the demo environment in this repository and to derived deployments. Cluster size and topology may change, but the loops and contracts described here remain the same.

## Backbone: Desired → Observed → Actionable

At product level, the platform runs on three feedback loops:

```d2
direction: right

Desired: {
  label: "Desired state (Git)"
  Code: "Manifests, values, policies, SLOs"
}

Observed: {
  label: "Observed state"
  Metrics: "Prometheus"
  Logs: "Loki"
  SLOs: "Pyrra"
}

Actionable: {
  label: "Actionable state"
  GitOps: "ArgoCD"
  Policy: "Kyverno (enforce/audit)"
  Events: "Argo Events"
}

Desired.Code -> Actionable.GitOps: "reconcile"
Desired.Code -> Actionable.Policy: "govern"
Observed.Metrics -> Actionable.Events: "emit → trigger"
Observed.SLOs -> Actionable.Events: "burn → playbook"
Actionable.GitOps -> Observed.Metrics: "deploy → measure"
```

As you explore the docs, map each capability to one or more of these loops. If something does not fit, it is either out of scope or a sign that a new abstraction might be needed.

## How to read the Concepts section

Use these pages as the conceptual backbone:

- [GitOps model](gitops-model.md) — bootstrap vs GitOps layers, AppProjects, ApplicationSets.
- [Networking & gateway](networking-gateway.md) — how traffic reaches services.
- [Scheduling & node pools](scheduling-nodepools.md) — capacity, priorities, and pools.
- [Security & policy model](security-policy-model.md) — CIA view, Kyverno, Vault, ESO.
- [Secrets management architecture](../architecture/secrets.md) — detailed secrets flows.

Read them after you have:

1. Deployed the platform once (Getting Started).
2. Skimmed [Architecture overview](../architecture/overview.md).

From there, Concepts give you the mental model needed to change the platform safely.
