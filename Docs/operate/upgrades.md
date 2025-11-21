---

# Upgrades — Choreography, gates, and rollbacks

Upgrades should feel boring. Make order and gates explicit, and test with disposable clusters before touching shared environments.

## Upgrade choreography (texto)

1) **Plan**: leer release notes, chequear matriz de compatibilidad (Cilium, K8s, CRDs).  
2) **Stage**: cluster efímero (`task deploy`), validar salud + dashboards + SLOs.  
3) **Prod**: ventana acordada, prechecks, manual gate; aplicar en orden.  
4) **Observar**: después del roll, validar Apps Healthy/Synced y SLO burn rate.  

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
