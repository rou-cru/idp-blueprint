---
title: Upgrades
sidebar:
  label: Upgrades
  order: 1
---
---


Upgrades should feel boring. Make order and gates explicit, and test with disposable clusters before touching shared environments.

## Upgrade choreography (concise)

1) **Plan**: read release notes, check compatibility matrix (Cilium, K8s, CRDs).  
2) **Stage**: ephemeral cluster (`task deploy`), validate health + dashboards + SLOs.  
3) **Prod**: agreed window, prechecks, manual gate; apply in order.  
4) **Observe**: after the roll, verify Apps Healthy/Synced and SLO burn rate.  

Recommended order:

1) CRDs and controllers (Kyverno, ESO, cert-manager) → 2) Networking (Cilium) → 3) GitOps (ArgoCD) → 4) Stacks (observability, security, CI/CD).

## Gates that matter

- SLO budget available (don’t ship if burn rate high).
- Health: pods Ready, Applications Healthy+Synced.
- Backout path: clear roll‑forward/back plan.

## Rollout patterns

- Pinned versions in values/overlays; single source of truth.
- Sync waves and dependency order explicit in Git.
- Small blast radius: upgrade one stack at a time.

![Upgrade canary](../assets/images/operate/upgrade-canary.jpg){ loading=lazy }
