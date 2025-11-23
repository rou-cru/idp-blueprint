---
title: ApplicationSets Patterns — Many apps, one generator
sidebar:
  label: ApplicationSets
  order: 7
---
---


ApplicationSets turn folder structure into Applications. One commit → one rollout.
For the full control‑plane model, see
[`GitOps, Policy, and Eventing`](../concepts/gitops-model.md).

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
