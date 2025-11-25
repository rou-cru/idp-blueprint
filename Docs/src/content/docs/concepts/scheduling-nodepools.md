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
Priorities.Infra -> Pools.Infra
Priorities.Events -> Pools.Infra
Priorities.Observ -> Pools.Infra
Priorities.Policy -> Pools.Infra
Priorities.CICD -> Pools.Work
Priorities.Dash -> Pools.Work
Priorities.Users -> Pools.Work
```

## Detailed Scheduling Architecture (C3)

This diagram shows how Kubernetes scheduler makes placement decisions based on PriorityClasses, node labels, taints/tolerations, and resource availability.

```d2
direction: down

classes: {
  sched: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  prio: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  node: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  pod: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
}

Scheduler: {
  class: sched
  label: "Kubernetes Scheduler"

  Decision: {
    label: "Scheduling Decision"
    Priority: "1. Check PriorityClass"
    Resources: "2. Check resources (requests)"
    Affinity: "3. Check node selector/affinity"
    Taints: "4. Check taints/tolerations"
    Pressure: "5. Eviction if needed"
  }
}

PriorityClasses: {
  class: prio
  label: "PriorityClasses (IT/priorityclasses/)"

  Tier1: {
    label: "Tier 1 - Critical Infrastructure"
    Infra: "platform-infrastructure (10000)\nVault, ArgoCD, cert-manager"
    Events: "platform-events (9500)\nArgo Events"
  }

  Tier2: {
    label: "Tier 2 - Essential Platform"
    Policy: "platform-policy (9000)\nKyverno"
    Security: "platform-security (8500)\nTrivy"
    Observability: "platform-observability (8000)\nPrometheus, Loki"
  }

  Tier3: {
    label: "Tier 3 - Developer Services"
    CICD: "platform-cicd (7000)\nWorkflows Controller"
    Dashboards: "platform-dashboards (6000)\nGrafana, Backstage"
  }

  Tier4: {
    label: "Tier 4 - Execution & Users"
    Execution: "cicd-execution (5000)\nWorkflow pods"
    Users: "user-workloads (1000)"
    Unclassified: "unclassified-workload (0)"
  }
}

Nodes: {
  class: node
  label: "Node Pools"

  ControlPlane: {
    label: "Control Plane Node"
    Labels: "node-role: control-plane"
    Taints: "NoSchedule (control-plane)"
    Tolerations: "Critical pods only"
  }

  InfraNodes: {
    label: "Infrastructure Nodes"
    Labels: "node-role: infrastructure"
    Resources: "High memory/CPU"
    Workloads: "Vault, ArgoCD, Prometheus"
  }

  WorkloadNodes: {
    label: "Workload Nodes"
    Labels: "node-role: workload"
    Resources: "Balanced"
    Workloads: "CI/CD, Dashboards, User apps"
  }
}

ResourcePressure: {
  class: sched
  label: "Resource Pressure Scenario"

  State: "Node memory 85% used"

  Action: {
    label: "Scheduler Actions"
    Step1: "1. Block new low-priority pods"
    Step2: "2. Evict lowest priority pods"
    Step3: "3. Preserve Tier 1-2 workloads"
  }

  Eviction: {
    label: "Eviction Order (lowest first)"
    First: "unclassified-workload (0)"
    Second: "user-workloads (1000)"
    Third: "cicd-execution (5000)"
    Protected: "platform-* (6000+) protected"
  }
}

Examples: {
  class: pod
  label: "Example Pod Placements"

  VaultPod: {
    label: "Vault Pod"
    Priority: "platform-infrastructure (10000)"
    NodeSelector: "node-role: infrastructure"
    Tolerations: "control-plane (as lifeboat)"
    Result: "→ Infra Node (or Control if needed)"
  }

  GrafanaPod: {
    label: "Grafana Pod"
    Priority: "platform-dashboards (6000)"
    NodeSelector: "none"
    Result: "→ Workload Node"
  }

  WorkflowPod: {
    label: "Workflow Execution Pod"
    Priority: "cicd-execution (5000)"
    NodeSelector: "none"
    Result: "→ Workload Node\n(evicted first if pressure)"
  }
}

Scheduler.Decision.Priority -> PriorityClasses: "consult"
PriorityClasses.Tier1 -> Nodes.InfraNodes: "prefer infra nodes"
PriorityClasses.Tier1 -> Nodes.ControlPlane: "tolerate (lifeboat)"
PriorityClasses.Tier2 -> Nodes.InfraNodes
PriorityClasses.Tier3 -> Nodes.WorkloadNodes
PriorityClasses.Tier4 -> Nodes.WorkloadNodes

Nodes -> ResourcePressure.State: "monitor"
ResourcePressure.Action -> PriorityClasses.Tier4: "evict first"
ResourcePressure.Eviction.Protected -> Examples.VaultPod: "always protected"
ResourcePressure.Eviction.First -> Examples.WorkflowPod: "evicted if needed"
```

### Scheduling Decision Flow

1. **Pod arrives** with `priorityClassName` specified
2. **Scheduler evaluates**:
   - Priority value (higher = more important)
   - Resource requests (CPU, memory)
   - Node selectors and affinity rules
   - Taints and tolerations
3. **Node selection**:
   - Prefers nodes matching labels
   - Respects taints (unless pod has tolerations)
   - Considers resource availability
4. **Under pressure**:
   - Scheduler blocks new low-priority pods
   - Kubelet evicts pods starting with lowest priority
   - Critical pods (Tier 1-2) remain running

### Lifeboat Strategy

Critical infrastructure pods (Vault, ArgoCD, Prometheus) have **tolerations for control-plane taint**. This allows them to schedule on the control plane node as a "lifeboat" if all infrastructure nodes fail.

**Toleration example**:
```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

This ensures observability and GitOps remain functional even if only the control plane survives.

### Priority Values Reference

| Priority | Value | Purpose | Eviction Risk |
|----------|-------|---------|---------------|
| platform-infrastructure | 10000 | Never evicted | None |
| platform-events | 9500 | Event mesh critical | None |
| platform-policy | 9000 | Admission control | None |
| platform-security | 8500 | Scanning essential | Very Low |
| platform-observability | 8000 | Monitoring critical | Low |
| platform-cicd | 7000 | Controller essential | Low |
| platform-dashboards | 6000 | UI nice-to-have | Medium |
| cicd-execution | 5000 | Workflow pods | High |
| user-workloads | 1000 | App workloads | Very High |
| unclassified-workload | 0 | Missing priority | Evicted First |

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
