# Scheduling & Node Pools

Workloads are organized using node labels to steer scheduling and isolation.

## Node pools

- Control plane: Kubernetes API and controllers
- Infrastructure: bootstrap and platform services (Vault, ArgoCD, cert-manager…)
- Workloads: GitOps-managed stacks (observability, security, CI/CD)

Kubernetes labels and taints/tolerations can be used to enforce separation.
See the [Node Pools diagram](../architecture/visual.md#3-node-pools-and-workload-deployment).

```d2
direction: right

Cluster: {
  label: "k3d-idp-demo"

  ControlPlane: {
    label: "Control Plane"
    node: "server-0"
  }

  InfraPool: {
    label: "Node Pool: IT Infrastructure (label: node-role=it-infra)"
    node: "agent-0"
    ArgoCD
    Vault
    Kyverno
    Prometheus
  }

  WorkloadPool: {
    label: "Node Pool: GitOps Workloads (label: node-role=k8s-workloads)"
    node: "agent-1"
    ArgoWorkflows: "Argo Workflows"
    SonarQube
  }

  DaemonSets: {
    label: "DaemonSets (run on all nodes)"
    Cilium: "Cilium Agent"
    FluentBit: "Fluent-bit"
    NodeExporter: "Node Exporter"
  }
}
```
