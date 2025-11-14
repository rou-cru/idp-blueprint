---
# Disaster Recovery — Rebuild fast, restore what matters

Aim for low RTO by making the rebuild path trivial and backups focused. Most of the platform is declarative and comes back from Git.

## DR priorities (order)

1) Cluster + networking (K8s + Cilium)
2) Secrets authority (Vault + ESO wiring)
3) GitOps brain (ArgoCD)
4) Observability + policy planes

## Rebuild flow (concept)

```d2
direction: right

Nuke: "New cluster (k3d/managed)"
Bootstrap: "Apply IT/ (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway)"
Restore: "Unseal + import Vault"
GitOps: "Apply AppProjects + ApplicationSets"
Converge: "Stacks sync"
Verify: "UIs, SLOs, Secrets"

Nuke -> Bootstrap -> Restore -> GitOps -> Converge -> Verify
```

![DR placeholder](../assets/images/operate/disaster-recovery.jpg){ loading=lazy }

## Checkpoints

- Gateway up (nip.io hosts reachable)
- ArgoCD Applications converge to Healthy/Synced
- ESO syncing secrets; workloads mount expected values
- SLOs calculating; alerts routed (even if no receivers)

## Tabletop exercises (recommended)

- “Lose the cluster” — rebuild from Git, restore Vault, validate.
- “Lose Vault” — restore policies/data, rebind ESO roles.
- “Lose Gateway” — reissue certs, verify routes.
