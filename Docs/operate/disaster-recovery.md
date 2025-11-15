# Disaster Recovery

This document outlines the disaster recovery strategy for the IDP Blueprint platform, designed specifically for resource-constrained edge environments.

## Design Context: Edge vs Cloud

The disaster recovery strategy differs from traditional cloud approaches due to edge computing constraints. Understanding these differences is critical to why the platform is designed this way.

| Feature | Cloud/Datacenter | Edge (This Platform) |
| :--- | :--- | :--- |
| **Scale & Resources** | Virtually unlimited, elastic | Fixed and limited (e.g., 3 nodes, limited RAM) |
| **Failure Domain** | Small, isolated failures (e.g., one VM in thousands) | Large impact; losing one node is 33% of capacity |
| **Connectivity** | High-speed, stable, and redundant | Can be unreliable or latent |
| **Recovery Model** | Redundancy and replacement (failed instances replaced quickly) | Resilience and graceful degradation (system survives with fewer resources) |
| **Primary Goal** | Maintain performance and availability through scaling | Maintain core functionality, even in degraded state |

In edge environments, the strategy prioritizes survival and operational continuity over maintaining full performance under all conditions.

## Tiered Service Criticality

The platform uses a tiered system where services are categorized by criticality. Kubernetes scheduling primitives (taints, tolerations, pod anti-affinity) control behavior during failures.

### Service Tiers

1. **Core Control Plane (Highest Priority):** `kube-apiserver`, `etcd`, scheduler, controller-manager. Essential for the cluster's basic operation.

2. **Critical Infrastructure (High Priority):**
   - **ArgoCD:** The GitOps engine. Essential for deploying, managing, and repairing applications.
   - **Prometheus:** Metrics and alerting. Provides the visibility necessary to understand cluster state.

3. **Important Services (Medium Priority):**
   - **Loki:** Log aggregation. Crucial for debugging but secondary to real-time monitoring and control.
   - **Argo Events:** Drives automation, but its temporary absence won't bring down existing applications.

4. **Application Workloads (Low Priority):** All other applications deployed on the cluster.

### Scheduling Implementation

The tiered system is enforced through Kubernetes scheduling configuration:

#### 1. Isolating the Control Plane

A taint is applied to the master node to prevent non-essential pods from being scheduled there, preserving resources for the Kubernetes control plane.

```bash
kubectl taint nodes <master-node-name> CriticalAddonsOnly=true:NoSchedule
```

#### 2. Enabling "Lifeboat" for Critical Infrastructure

ArgoCD and Prometheus have tolerations that allow them to schedule on the tainted master node if no other nodes are available.

```yaml
# In values.yaml for ArgoCD and Prometheus
tolerations:
- key: "CriticalAddonsOnly"
  operator: "Exists"
  effect: "NoSchedule"
```

This turns the master node into a last resort. It's not ideal to run workloads there, but it's better than a complete outage of core management and monitoring tools.

#### 3. Separating Critical Services

Pod anti-affinity with `preferredDuringSchedulingIgnoredDuringExecution` is used for Prometheus and Loki.

```yaml
# In prometheus.prometheusSpec.affinity and loki.affinity
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: <loki-or-prometheus>
      topologyKey: "kubernetes.io/hostname"
```

This rule tells the scheduler to try to keep these services on different nodes. The "preferred" nature allows the scheduler to ignore it during failures and consolidate onto the remaining worker node.

## Failure Scenarios

The tiered scheduling creates predictable responses to failures:

| Scenario | State | Description |
| :--- | :--- | :--- |
| **All nodes healthy** | Green | Prometheus and Loki run on separate worker nodes. ArgoCD and Argo Events are distributed. The master node is reserved for control plane components. |
| **One worker node fails** | Yellow (Degraded) | Pods from the failed node reschedule onto the remaining worker. Prometheus and Loki co-locate. Performance may degrade, but both services remain up. Priority classes evict lower-priority pods if necessary. |
| **Both worker nodes fail** | Red (Critical) | Major outage. ArgoCD and Prometheus reschedule onto the master node due to tolerations. Loki and Argo Events remain `Pending`. This provides minimal "limp-home" mode: you can see what's happening (Prometheus) and potentially fix the issue (ArgoCD). |
| **All nodes fail** | Black (Total Outage) | Entire cluster down. Recovery requires manual intervention to restore nodes and etcd from backup. |

## Recovery Priorities

When recovering from failures, follow this order:

1. **Kubernetes API and networking (Cilium):** Without these, nothing else can function.
2. **Identity and secrets (Vault, External Secrets):** Required for applications to authenticate and access credentials.
3. **GitOps reconciler (ArgoCD):** Enables automated recovery of other components.
4. **Observability and policy layers:** Provides visibility and governance.
5. **Application workloads:** Last to restore after infrastructure is stable.

## Trade-offs

This strategy makes deliberate compromises optimized for resilience in resource-constrained environments:

- **Performance vs. Availability:** Sacrifices some performance in degraded states (co-locating Prometheus and Loki) to maintain availability of both services.

- **Risk of Control Plane Instability:** Allowing workloads onto the master node is a calculated risk. By limiting this to only the most critical infrastructure (ArgoCD and Prometheus) and only as a last resort, the risk is mitigated. The alternative (complete loss of visibility and control) is worse.

- **Simplicity vs. Complexity:** This approach uses standard Kubernetes features (taints, tolerations, pod anti-affinity) rather than custom schedulers, reducing operational overhead.

## Recovery Runbooks

### Scenario 1: Single Worker Node Failure

**Symptoms:**
- Node shows `NotReady` in `kubectl get nodes`
- Pods from that node are in `Pending` or `Terminating` state

**Recovery Steps:**
1. Check node status: `kubectl describe node <node-name>`
2. If node is recoverable, investigate logs and restart kubelet
3. If node is lost, remaining worker absorbs workloads automatically
4. Monitor resource usage: `kubectl top nodes`
5. If resource pressure occurs, lower-priority pods are evicted per priority classes

**Expected State:** Yellow (degraded but operational)

### Scenario 2: Both Worker Nodes Failure

**Symptoms:**
- Only master node shows `Ready`
- ArgoCD and Prometheus pods on master node
- Loki, Argo Events, and application workloads in `Pending` state

**Recovery Steps:**
1. Verify critical services: `kubectl get pods -n argocd` and `kubectl get pods -n observability`
2. Use Prometheus to assess cluster state
3. Use ArgoCD to verify GitOps sync status
4. Restore or replace worker nodes
5. Once workers are healthy, pods will reschedule automatically

**Expected State:** Red (critical, minimal functionality)

### Scenario 3: Total Cluster Failure

**Symptoms:**
- No nodes accessible
- Kubernetes API unreachable

**Recovery Steps:**
1. Restore infrastructure (nodes)
2. Restore etcd from backup (see [Backup & Restore](backup-restore.md))
3. Verify control plane components start correctly
4. Verify Cilium initializes and networking is functional
5. Wait for ArgoCD to reconcile all applications from Git
6. Verify all critical services are healthy

**Expected State:** Black to Green (full recovery)

## Testing Disaster Recovery

The strategy should be tested periodically:

1. **Node Drain Test:** Drain a worker node and verify workloads reschedule correctly
2. **Multi-Node Failure Test:** Cordon both worker nodes and verify ArgoCD/Prometheus schedule on master
3. **etcd Backup/Restore Test:** Backup etcd, destroy cluster, restore from backup

Testing validates that the tiered scheduling works as designed and that recovery procedures are accurate.

## References

- [Backup & Restore](backup-restore.md): etcd backup procedures
- [Architecture Overview](../architecture/overview.md): Resilience strategy in broader context
- [Kubernetes Documentation: Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Kubernetes Documentation: Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
