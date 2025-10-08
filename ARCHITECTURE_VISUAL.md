# IDP Visual Architecture

This document describes the platform's architecture, its workflows, and its
execution environment through diagrams.

## 1. General Architecture and GitOps Flow

This diagram shows the high-level view of the workflow, from the definition in a Git repository to the deployment and operation of the components within the Kubernetes cluster.

```mermaid
graph TD
    GitRepo[Git Repository]

    subgraph K8sCluster [Kubernetes Cluster]
        direction TB
        
        subgraph CoreInfrastructure [Core Infrastructure]
            direction LR
            Cilium[Cilium]
            CertManager[Cert-Manager]
            Vault[Vault]
            ESO[External Secrets Operator]
        end

        subgraph GitOpsPolicyEngine [GitOps and Policy Engine]
            direction LR
            ArgoCD[ArgoCD]
            Kyverno[Kyverno]
            PolicyReporter[Policy Reporter]
        end

        subgraph AppStacks [Application Stacks]
            direction TB
            
            subgraph ObservabilityStack [Observability Stack]
                direction LR
                Prometheus[Prometheus]
                Grafana[Grafana]
                Loki[Loki]
                FluentBit[Fluent-bit]
            end

            subgraph CICDStack [CI/CD Stack]
                direction LR
                Jenkins[Jenkins]
                SonarQube[SonarQube]
            end

            subgraph SecurityStack [Security Stack]
                direction LR
                Trivy[Trivy Operator]
            end
        end
        
        K8sApi[Kubernetes API Server]
    end

    GitRepo -->|Defines State| ArgoCD
    ArgoCD -->|Applies Manifests| AppStacks
    ArgoCD -->|Creates Resources| K8sApi
    K8sApi -->|Validates Requests| Kyverno
    Kyverno -->|Enforces Policies| K8sApi
    Kyverno -->|Reports Status| PolicyReporter
    Vault -->|Provides Secrets| ESO
    ESO -->|Syncs Secrets| K8sApi
    FluentBit -->|Collects Logs| Loki
    Prometheus -->|Scrapes Metrics| Grafana
    Loki -->|Provides Logs| Grafana
    Jenkins -->|Sends analysis to| SonarQube
    Trivy -->|Scans Resources| K8sApi
    CertManager -->|Manages Certificates| K8sApi
```

## 2. Node Pools and Workload Deployment

Within the Hub cluster, nodes are segmented into logical "Node Pools" using
labels to isolate workloads. This classification is the basis for future
scheduling rules with `tolerations` and `affinity`.

```mermaid
graph TD
    subgraph IDPHubCluster [IDP Hub Cluster]
        subgraph NodePool_Infra [Node Pool: Infra]
            direction TB
            infra_node[k3s-agent-0]
        end

        subgraph NodePool_Apps [Node Pool: Apps]
            direction TB
            apps_node[k3s-agent-1]
        end

        subgraph NodePool_CP [Node Pool: Control Plane]
            direction TB
            cp_node[k3s-server-0]
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
            appA[App A]
            appB[App B]
        end
    end

    Workloads_Platform -->|Scheduled on| NodePool_Infra
    Workloads_Apps -->|Scheduled on| NodePool_Apps
```

## 3. Certificate Management Flow

This flow shows how a resource (e.g., an `Ingress`) automatically obtains a TLS
certificate.

```mermaid
sequenceDiagram
    participant I as Ingress Resource
    participant CM as cert-manager
    participant CI as ClusterIssuer
    participant CAS as CA Secret
    participant FinalTLS as Final TLS Secret

    I->>+CM: 1. Requests certificate via annotation
    CM->>+CI: 2. Reads the Issuer configuration
    CI-->>-CM: spec.ca.secretName: idp-demo-ca-secret
    CM->>+CAS: 3. Loads the root CA from the Secret
    CAS-->>-CM: CA private key and certificate
    CM-->>CM: 4. Signs a new certificate
    CM->>+FinalTLS: 5. Creates/Updates the final Secret for the Ingress
    FinalTLS-->>-I: 6. Mounts the TLS Secret
```

## 4. Secret Management Flow

This flow details how an application securely consumes a secret from Vault
without having direct credentials.

```mermaid
sequenceDiagram
    participant App as Application Pod
    participant K8S_Secret as Kubernetes Secret
    participant ES_CR as ExternalSecret CR
    participant ESO as External Secrets Operator
    participant CSS as ClusterSecretStore
    participant Vault

    App->>+K8S_Secret: 1. Needs to mount a K8s Secret
    K8S_Secret-->>-App: Not found or needs update
    ESO->>+ES_CR: 2. Watches the ExternalSecret resource
    ES_CR-->>-ESO: spec.secretStoreRef: vault-secretstore
    ESO->>+CSS: 3. Reads the referenced ClusterSecretStore
    CSS-->>-ESO: provider: vault, auth: kubernetes
    ESO->>+Vault: 4. Authenticates and requests the secret
    Vault-->>-ESO: Returns the secret data
    ESO->>+K8S_Secret: 5. Creates/Updates the Kubernetes Secret
    K8S_Secret-->>App: 6. The Secret is mounted in the Pod
```

## 5. Observability Data Flow

This diagram details how metrics and logs are collected, processed, and visualized on the platform.

```mermaid
graph TD
    subgraph Kubernetes Nodes
        direction LR
        AppPod[App Pod]
        Kubelet[Kubelet]
        NodeExporter[Node Exporter]
        ContainerLogs[Container Log Files]
    end

    subgraph Observability Namespace
        direction LR
        Prometheus[Prometheus]
        Loki[Loki]
        Grafana[Grafana]
        KSM[Kube-State-Metrics]
        FluentBit[Fluent-bit DaemonSet]
    end

    AppPod -->|Generates Logs| ContainerLogs
    AppPod -->|Exposes Metrics| Prometheus
    Kubelet -->|Exposes Metrics| Prometheus
    
    ContainerLogs -->|Tailed by| FluentBit
    FluentBit -->|Forwards Logs| Loki

    NodeExporter -->|Scrapes Node Metrics| Prometheus
    KSM -->|Scrapes Cluster Metrics| Prometheus

    Prometheus -->|Data Source| Grafana
    Loki -->|Data Source| Grafana
```

## 6. Security Scanning Flow with Trivy

This diagram illustrates how the Trivy operator scans cluster workloads for vulnerabilities.

```mermaid
sequenceDiagram
    participant User as User/ArgoCD
    participant K8sApi as Kubernetes API
    participant TrivyOp as Trivy Operator
    participant Workload as e.g., Deployment, Pod
    participant Report as VulnerabilityReport CRD

    User->>K8sApi: 1. Creates/Updates a Workload
    K8sApi-->>TrivyOp: 2. Watches resource changes
    TrivyOp->>Workload: 3. Discovers container images
    TrivyOp->>TrivyOp: 4. Scans images for vulnerabilities
    TrivyOp->>K8sApi: 5. Creates/Updates VulnerabilityReport
    K8sApi-->>Report: 6. Stores the report
```

## 7. GitOps Structure with ApplicationSets

This diagram explains the "App of Apps" pattern. The `ApplicationSet` resources in ArgoCD monitor directories in Git. When they find subdirectories that match their generator, they automatically create child `Application` resources, one for each stack component.

```mermaid
graph LR
    subgraph Git Repository
        direction TB
        RepoDir[K8s/ Directory]
        ObsDir[observability/]
        SecDir[security/]
        CiCdDir[cicd/]
    end

    subgraph ArgoCD
        direction TB
        AppSetObs[ApplicationSet observability]
        AppSetSec[ApplicationSet security]
        AppSetCiCd[ApplicationSet cicd]

        AppPrometheus[App: obs-prometheus]
        AppGrafana[App: obs-grafana]
        AppLoki[App: obs-loki]
        AppTrivy[App: sec-trivy]
    end

    GitRepo -->|Monitored by| AppSetObs
    GitRepo -->|Monitored by| AppSetSec
    GitRepo -->|Monitored by| AppSetCiCd

    AppSetObs -->|Generates| AppPrometheus
    AppSetObs -->|Generates| AppGrafana
    AppSetObs -->|Generates| AppLoki
    AppSetSec -->|Generates| AppTrivy
```