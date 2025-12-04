---
title: ApplicationSets
sidebar:
  label: ApplicationSets
  order: 7
---
---

ApplicationSets turn folder structure into Applications. One commit → one rollout.
For the full control‑plane model, see
[`GitOps, Policy, and Eventing`](../concepts/gitops-model.md).

## How it works in this platform

Each stack (observability, cicd, security, backstage, events) has its own ApplicationSet that
lives alongside the components it manages. Pattern: `K8s/<stack>/applicationset-<stack>.yaml`.

The ApplicationSet uses a **Git directory generator** to scan `K8s/<stack>/*` folders. When
you commit a new folder like `K8s/observability/kubecost/`, ArgoCD automatically creates an
Application named `observability-kubecost` without manual intervention.

This keeps Applications declarative: no clicking in UIs, no imperative `argocd app create`
commands. Git structure = cluster state.

### Visual mapping

How Git folders map to ArgoCD Applications:

![ApplicationSet Mapping](../assets/diagrams/operate/applicationset-mapping.svg)

## Generators

- Directory generator: map `K8s/<stack>/*` → Applications.
- List/cluster generators (future): multi-cluster fan‑out.

## Templates that matter

- Common labels/annotations; sync options (`ServerSideApply`, `PruneLast`).
- Automated prune + self‑heal; retries with backoff.
- `ignoreDifferences` for noisy fields (e.g., webhook `caBundle`).

## Validate before merging

- Dry‑run locally; preview in ArgoCD UI after pushing to a branch.
- Keep the template minimal; push app‑specific knobs into values/overlays.
