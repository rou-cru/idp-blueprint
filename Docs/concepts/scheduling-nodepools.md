# Scheduling, Priority, and Node Pools — making capacity intentional

The platform treats capacity as a product feature. PriorityClasses and pools ensure critical planes remain responsive even under pressure.

## Mental model

```d2
direction: right

Priority: {
  Infra: "platform-infrastructure\n(Vault, ArgoCD, cert-manager)"
  Observ: "platform-observability\n(Prometheus, Loki)"
  Policy: "platform-policy\n(Kyverno)"
  CICD: "platform-cicd\n(Argo Workflows)"
  Dash: "platform-dashboards\n(Grafana)"
  Exec: "cicd-execution\n(Workflow pods)"
}

Pools: {
  ControlPlane: "K8s control plane"
  InfraNodes: "infra services"
  WorkloadNodes: "apps + CI/CD"
}

Priority.Infra -> Pools.InfraNodes
Priority.Observ -> Pools.InfraNodes
Priority.Policy -> Pools.InfraNodes
Priority.CICD -> Pools.WorkloadNodes
Priority.Dash -> Pools.WorkloadNodes
Priority.Exec -> Pools.WorkloadNodes
```

Key points:
- PriorityClasses are declared in `IT/priorityclasses/priorityclasses.yaml` and
  include: `platform-infrastructure`, `platform-policy`, `platform-security`,
  `platform-observability`, `platform-cicd`, `platform-dashboards`,
  `user-workloads`, `cicd-execution`, and the global default
  `unclassified-workload`.
- Every chart sets `priorityClassName` where appropriate (enforced by checks).
  Fail fast if missing.
- Pool separation reduces noisy neighbors; DaemonSets run everywhere (Cilium,
  Fluent‑bit, Node Exporter).
- HA is a dial: enable for control planes as you grow.

![Cluster view](../assets/images/after-deploy/k9s-overview.jpg){ loading=lazy }
