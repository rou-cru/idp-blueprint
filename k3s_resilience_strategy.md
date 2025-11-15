# High-Availability and Disaster Recovery Strategy for the K3s Cluster

This document outlines the strategy for ensuring the resilience and high availability of our K3s-based platform, particularly in the context of its deployment in resource-constrained edge environments.

## 1. Understanding the Environment: Cloud vs. Edge

The design of our high-availability strategy is fundamentally shaped by the constraints of an edge computing environment, which differs significantly from a traditional cloud or data center setup.

| Feature | Cloud/Datacenter (Traditional SRE) | Edge (Our K3s Cluster) |
| :--- | :--- | :--- |
| **Scale & Resources** | Virtually unlimited, elastic. | **Fixed and limited** (e.g., 3 nodes, limited RAM). |
| **Failure Domain** | Small, isolated failures (e.g., one VM in thousands). | Large impact; losing one node is **33% of capacity**. |
| **Connectivity** | High-speed, stable, and redundant. | Can be unreliable or latent. |
| **Recovery Model** | **Redundancy and replacement.** Failed instances are quickly replaced by new ones. | **Resilience and graceful degradation.** The system must survive with fewer resources. |
| **Primary Goal** | Maintain performance and availability through scaling. | Maintain core functionality, even in a degraded state. |

Given these constraints, our strategy prioritizes **survival and operational continuity** over maintaining full performance under all conditions.

## 2. Core Resiliency Strategy: Tiered Services and Controlled Failover

Our approach is to create a tiered system of services and use Kubernetes scheduling primitives to control how they behave during a failure.

### Service Tiers:

1.  **Core Control Plane (Highest Priority):** `kube-apiserver`, `etcd`, etc. These are essential for the cluster's basic operation.
2.  **Critical Infrastructure (High Priority):**
    *   **ArgoCD:** The "brain" of our GitOps workflow. Essential for deploying, managing, and repairing applications.
    *   **Prometheus:** Our "eyes." Provides the metrics and alerting necessary to understand the state of the cluster.
3.  **Important Services (Medium Priority):**
    *   **Loki:** Our "memory." Provides log aggregation, which is crucial for debugging but secondary to real-time monitoring and control.
    *   **Argo Events:** Drives our automation, but its temporary absence will not bring down existing applications.
4.  **Application Workloads (Low Priority):** All other applications deployed on the cluster.

### Scheduling Implementation:

To enforce this hierarchy and ensure predictable behavior during failures, we will use a combination of **Taints, Tolerations, and Pod Anti-Affinity**.

1.  **Isolating the Control Plane:**
    *   We will apply a `taint` to the master node. This prevents any non-essential pods from being scheduled on it, preserving its resources for the Kubernetes control plane itself.
    *   **Command:** `kubectl taint nodes <master-node-name> CriticalAddonsOnly=true:NoSchedule`

2.  **Enabling "Lifeboat" for Critical Infrastructure:**
    *   We will add a `toleration` to the **ArgoCD** and **Prometheus** deployments. This allows them, and only them, to be scheduled on the tainted master node if no other nodes are available.
    *   **YAML Snippet (for `values.yaml`):**
        ```yaml
        tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
          effect: "NoSchedule"
        ```
    *   This turns the master node into a "lifeboat." It's not ideal to run workloads there, but it's better than a complete outage of our core management and monitoring tools.

3.  **Separating Critical Services:**
    *   We will use `podAntiAffinity` with a `preferredDuringSchedulingIgnoredDuringExecution` rule for **Prometheus** and **Loki**.
    *   **YAML Snippet (for `prometheus.prometheusSpec.affinity` and `loki.affinity`):**
        ```yaml
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: <loki-or-prometheus>
              topologyKey: "kubernetes.io/hostname"
        ```
    *   This rule tells the scheduler to *try* to keep these services on different nodes. If a node fails, the "preferred" nature of the rule allows the scheduler to ignore it and consolidate them onto the remaining worker node.

## 3. Failure Scenarios and Expected Outcomes

This strategy creates a predictable, tiered response to failures:

| Scenario | State | Description |
| :--- | :--- | :--- |
| **All nodes healthy** | **Green** | Prometheus and Loki run on separate worker nodes. ArgoCD and Argo Events are also distributed. The master node is reserved for control plane components. |
| **One worker node fails** | **Yellow (Degraded)** | The pods from the failed node (e.g., Loki) are rescheduled onto the remaining worker node. Prometheus and Loki are now co-located. Performance may be degraded, but both services are **up and running**. The `platform-infrastructure` and `platform-observability` pods will evict lower-priority pods if necessary. |
| **Both worker nodes fail** | **Red (Critical)** | This is a major outage. The scheduler will attempt to move all workloads. Because of the `toleration`, **ArgoCD and Prometheus will be rescheduled onto the master node**. Loki and Argo Events will remain `Pending` as they do not have the toleration. This provides a minimal, "limp-home" mode where you can still see what's happening (Prometheus) and potentially fix the issue (ArgoCD). |
| **All nodes fail** | **Black (Total Outage)** | The entire cluster is down. Recovery will require manual intervention to restore the nodes and etcd from backup. |

## 4. Trade-offs and Justification

This strategy is a deliberate compromise optimized for resilience in a resource-constrained environment.

*   **Performance vs. Availability:** We are explicitly choosing to sacrifice some performance in a degraded state (by co-locating Prometheus and Loki) in order to maintain the availability of both services.
*   **Risk of Control Plane Instability:** Allowing workloads onto the master node is a calculated risk. However, by limiting this to only the most critical infrastructure (ArgoCD and Prometheus) and only in a "last resort" scenario, we mitigate the risk. The alternative is a complete loss of visibility and control, which is a far greater risk.
*   **Simplicity vs. Complexity:** While more complex than a simple default setup, this approach uses standard, well-understood Kubernetes features. It avoids the need for custom schedulers, which would add significant operational overhead.

By implementing this tiered, resilient scheduling strategy, we can ensure that the cluster is as robust as possible, can automatically handle common failure scenarios, and provides the necessary tools for recovery even in the face of major outages.