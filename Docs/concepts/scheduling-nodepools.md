# Scheduling & Node Pools

Workloads are organized using node labels to steer scheduling and isolation.

## Node pools

- Control plane: Kubernetes API and controllers
- Infrastructure: bootstrap and platform services (Vault, ArgoCD, cert-manager…)
- Workloads: GitOps-managed stacks (observability, security, CI/CD)

Kubernetes labels and taints/tolerations can be used to enforce separation.
See the [Node Pools diagram](../architecture/visual.md#_3-node-pools-and-workload-deployment).

## Diagram

=== "D2"

```d2
direction: right

Cluster: {
  label: "k3d-idp-demo"
  CP: "Control Plane\nserver-0"
  INFRA: "Node Pool: IT Infrastructure\nagent-0\nlabel: node-role=it-infra"
  WORK: "Node Pool: GitOps Workloads\nagent-1\nlabel: node-role=k8s-workloads"
}

Platform: {
  Argo: ArgoCD
  Vault: Vault
  Kyverno: Kyverno
  Prom: Prometheus
}

Apps: {
  Workflows: "Argo Workflows"
  Sonar: SonarQube
}

DaemonSets: {
  Cilium: "Cilium Agent"
  Fluent: "Fluent-bit"
  NodeExp: "Node Exporter"
}

Platform.Argo -> Cluster.INFRA: "scheduled on"
Platform.Vault -> Cluster.INFRA
Platform.Kyverno -> Cluster.INFRA
Platform.Prom -> Cluster.INFRA
Apps.Workflows -> Cluster.WORK: "scheduled on"
Apps.Sonar -> Cluster.WORK
DaemonSets.Cilium -> Cluster.CP
DaemonSets.Cilium -> Cluster.INFRA
DaemonSets.Cilium -> Cluster.WORK
DaemonSets.Fluent -> Cluster.CP
DaemonSets.Fluent -> Cluster.INFRA
DaemonSets.Fluent -> Cluster.WORK
DaemonSets.NodeExp -> Cluster.CP
DaemonSets.NodeExp -> Cluster.INFRA
DaemonSets.NodeExp -> Cluster.WORK
```

=== "Mermaid"

```mermaid
graph TD
    subgraph IDPHubCluster [IDP Hub Cluster - k3d-idp-demo]
        subgraph NodePool_Infra [Node Pool: IT Infrastructure]
            direction TB
            infra_node[k3d-idp-demo-agent-0<br/>Label: node-role=it-infra]
        end

        subgraph NodePool_Apps [Node Pool: GitOps Workloads]
            direction TB
            apps_node[k3d-idp-demo-agent-1<br/>Label: node-role=k8s-workloads]
        end

        subgraph NodePool_CP [Node Pool: Control Plane]
            direction TB
            cp_node[k3d-idp-demo-server-0<br/>Control Plane + etcd]
        end

        subgraph Workloads_Platform [Platform Services]
            direction LR
            argo[ArgoCD]
            vault[Vault]
            prom[Prometheus]
            kyv[Kyverno]
        end

        subgraph Workloads_Apps [Application Workloads]
            direction LR
            workflows[Argo Workflows]
            sonar[SonarQube]
        end

        subgraph DaemonSets_AllNodes [DaemonSets - All Nodes]
            direction LR
            cilium[Cilium Agent]
            fluent[Fluent-bit]
            node_exp[Node Exporter]
        end
    end

    Workloads_Platform -.->|Scheduled on| NodePool_Infra
    Workloads_Apps -.->|Scheduled on| NodePool_Apps
    DaemonSets_AllNodes -->|Runs on| NodePool_CP
    DaemonSets_AllNodes -->|Runs on| NodePool_Infra
    DaemonSets_AllNodes -->|Runs on| NodePool_Apps
```
