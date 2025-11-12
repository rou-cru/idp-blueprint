# Scheduling & Node Pools

Workloads are organized using node labels to steer scheduling and isolation.

## Node pools

- Control plane: Kubernetes API and controllers
- Infrastructure: bootstrap and platform services (Vault, ArgoCD, cert-manager…)
- Workloads: GitOps-managed stacks (observability, security, CI/CD)

Kubernetes labels and taints/tolerations can be used to enforce separation.
See the [Node Pools diagram](../architecture/visual.md#_3-node-pools-and-workload-deployment).

