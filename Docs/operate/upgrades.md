# Upgrades

Plan and execute upgrades for platform components and the cluster.

## Strategy

- Pin versions in Helm charts/Kustomize overlays
- Test in a disposable cluster with `task deploy`
- Apply progressive rollouts and monitor health

## Topics to Cover

- ArgoCD & ApplicationSets
- Cilium, cert-manager, Vault, ESO
- Observability stack
- Kyverno and Policy Reporter
- Trivy Operator
