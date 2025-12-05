---
title: Scheduling & NodePools
sidebar:
  label: Scheduling & NodePools
  order: 5
---

The platform treats capacity as a product feature. PriorityClasses and pools ensure critical
planes remain responsive even under pressure.

## Mental model

![Scheduling Mental Model](scheduling-nodepools-1.svg)

## Detailed Scheduling Architecture

This diagram shows how Kubernetes scheduler makes placement decisions based on
PriorityClasses, node labels, taints/tolerations, and resource availability.

![Detailed Scheduling Architecture](scheduling-nodepools-2.svg)

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

Critical infrastructure pods (Vault, ArgoCD, Prometheus) have **tolerations for control-
plane taint**. This allows them to schedule on the control plane node as a "lifeboat" if all
infrastructure nodes fail.

**Toleration example**:

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

This ensures observability and GitOps remain functional even if only the control plane
survives.

### How PriorityClasses are defined here

`IT/priorityclasses/priorityclasses.yaml` is the authoritative source applied by ArgoCD. We
use four intent buckets—control plane, platform services, shared UIs, and execution/user
workloads—where the relative ordering matters more than exact integer values. Higher buckets
are protected from preemption, while execution and user tiers are evicted first under
pressure. Critical pods tolerate control-plane taints to use the control plane as a
"lifeboat" if infrastructure nodes fail.

When adjusting priorities, change the manifests first; update this page only to describe the
rationale and the relative ordering.
| unclassified-workload | 0 | Missing priority | Evicted First |

Key points:

PriorityClasses are declared in `IT/priorityclasses/priorityclasses.yaml` and include tiers
for infrastructure, events, policy, security, observability, CI/CD, dashboards, and user
workloads. Every chart must set a `priorityClassName` to fail fast if missing. Pool
separation reduces noisy neighbors, while DaemonSets like Cilium and Fluent-bit run
everywhere. High availability is a dial that can be enabled for control planes as the
platform grows.

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
