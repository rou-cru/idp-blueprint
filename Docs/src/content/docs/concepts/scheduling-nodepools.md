---
title: Scheduling, Priority, and Node Pools — making capacity intentional
sidebar:
  label: Scheduling & NodePools
  order: 5
---

The platform treats capacity as a product feature. PriorityClasses and pools ensure critical planes remain responsive even under pressure.

## Mental model

```d2
direction: right

classes: { prio: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           pool: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Priorities: {
  class: prio
  Infra: "platform-infrastructure\n(Vault, ArgoCD, cert-manager)"
  Events: "platform-events\n(Argo Events)"
  Observ: "platform-observability\n(Prometheus, Loki)"
  Policy: "platform-policy\n(Kyverno)"
  CICD: "platform-cicd / cicd-execution\n(Workflows controller + pods)"
  Dash: "platform-dashboards\n(Grafana)"
  Users: "user-workloads\n(default)"
}

Pools: {
  class: pool
  Control: "Control plane node"
  Infra: "Infra nodes"
  Work: "Workload nodes"
}

Priorities.Infra -> Pools.Infra
Priorities.Events -> Pools.Infra
Priorities.Observ -> Pools.Infra
Priorities.Policy -> Pools.Infra
Priorities.CICD -> Pools.Work
Priorities.Dash -> Pools.Work
Priorities.Users -> Pools.Work
```

Key points:

- PriorityClasses are declared in `IT/priorityclasses/priorityclasses.yaml` and
  include: `platform-infrastructure`, `platform-events`, `platform-policy`,
  `platform-security`, `platform-observability`, `platform-cicd`,
  `platform-dashboards`, `user-workloads`, `cicd-execution`, and the global
  default `unclassified-workload`.
- Every chart sets `priorityClassName` where appropriate (enforced by checks).
  Fail fast if missing.
- Pool separation reduces noisy neighbors; DaemonSets run everywhere (Cilium,
  Fluent‑bit, Node Exporter).
- HA is a dial: enable for control planes as you grow.

![Cluster view](../assets/images/after-deploy/k9s-overview.jpg){ loading=lazy }

## Zero-Downtime Rolling Updates

Critical platform components use `maxUnavailable: 0` in their rolling update strategy
to ensure service continuity during updates. This forces Kubernetes to create the new
pod and wait for it to be ready **before** terminating the old one.

### Why not apply everywhere?

Requiring zero unavailability has trade-offs:

| Consideration | Impact |
|---------------|--------|
| **Resource overhead** | Needs headroom for surge pods during updates |
| **Scheduler complexity** | Must find capacity for both old and new pods simultaneously |
| **Update latency** | Updates take longer since we wait for full readiness |

For non-critical components (dashboards, reports, scans), a brief interruption is
acceptable and allows the scheduler to work more efficiently.

### Components with Zero-Downtime Strategy

These workloads use `maxUnavailable: 0` because their unavailability would block
platform operations:

| Component | Why Critical |
|-----------|--------------|
| **Cilium Operator** | CNI reconciliation stops → network policies don't update |
| **Vault** | Secret source of truth → all secret syncs fail |
| **ArgoCD (all)** | GitOps engine → deployments stop, UI/API unavailable |
| **Cert-Manager** | Certificate automation stops → TLS renewals fail |
| **External Secrets** | Secret sync stops → workloads can't get credentials |
| **Kyverno Admission** | Policy enforcement stops → deployments may be blocked |
| **Argo Workflows Controller** | Workflow execution stops → CI/CD pipelines stall |
| **Argo Events Controller** | Event mesh stops → no reactive automation |

### Components that Accept Brief Downtime

These workloads use default rolling update strategy (typically `maxUnavailable: 25%`)
as a trade-off for simpler scheduling:

| Component | Rationale |
|-----------|-----------|
| **Grafana** | Visualization only, no data loss |
| **Policy Reporter** | Compliance dashboards, reports regenerate |
| **Prometheus** | Metrics buffered, brief gap acceptable |
| **Loki** | Logs buffered by Fluent-bit |
| **SonarQube** | Analysis can wait, stateful data persists |
| **Trivy Operator** | Scans can be delayed |
| **Argo Workflows Server** | UI only, controller keeps workflows running |
| **Kyverno Background/Cleanup** | Non-blocking operations |

### Configuration Pattern

Zero-downtime strategy in Helm values:

```yaml
deploymentStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```

For StatefulSets (like Vault), use `updateStrategyType: RollingUpdate`.
