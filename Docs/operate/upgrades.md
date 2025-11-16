---
# Upgrades — Choreography, gates, and rollbacks

Upgrades should feel boring. Make order and gates explicit, and test with disposable clusters before touching shared environments.

## Choreography (order that sticks)

```d2
direction: right

Plan: {
  Readme: "Release notes + breaking changes"
  Matrix: "Compatibility (Cilium, K8s, CRDs)"
}

Stage: {
  Ephemeral: "k3d: task deploy"
  Validate: "health + dashboards + SLOs"
}

Prod: {
  Windows: "change window"
  Gates: "prechecks + manual gate"
  Roll: "apply in order"
}

Plan -> Stage: test
Stage -> Prod.Gates: promote
Prod.Roll -> Validate: observe
```

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
