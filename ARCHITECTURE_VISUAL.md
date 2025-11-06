# IDP Visual Architecture

This document describes the platform's architecture, its workflows, and its
execution environment through diagrams.

## 1. General Architecture and GitOps Flow

This diagram shows the high-level view of the workflow, from the definition in a Git
repository to the deployment and operation of the components within the Kubernetes
cluster.

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
                Workflows[Argo Workflows]
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
    Workflows -->|Triggers analysis in| SonarQube
    Trivy -->|Scans Resources| K8sApi
    CertManager -->|Manages Certificates| K8sApi
```

## 2. Helm to Pods Deployment Flow

This diagram shows the complete deployment chain from Helm charts to running pods,
illustrating how different layers (Bootstrap, GitOps) interact.

```mermaid
graph TB
    subgraph Bootstrap [Bootstrap Layer - IT/]
        H1[Helm: cilium v1.18.2]
        H2[Helm: vault v0.31.0]
        H3[Helm: argocd v8.5.8]
        H4[Helm: cert-manager v1.18.2]
        H5[Helm: external-secrets v0.20.2]
    end

    subgraph GitOps [GitOps Layer - K8s/]
        direction TB

        subgraph ArgoCD_Core [ArgoCD Applications]
            APP1[App: observability-fluent-bit]
            APP2[App: observability-loki]
            APP3[App: observability-kube-prometheus-stack]
            APP4[App: cicd-argo-workflows]
            APP5[App: security-trivy]
            APP6[App: platform-policies]
        end

        subgraph Kustomize [Kustomize + Helm Charts]
            K1[Kustomize: fluent-bit<br/>helmCharts: fluent-bit v0.54.0]
            K2[Kustomize: loki<br/>helmCharts: loki v6.42.0]
            K3[Kustomize: kube-prometheus-stack<br/>helmCharts: v77.14.0]
            K4[Kustomize: argo-workflows<br/>helmCharts: argo-workflows v0.45.11]
            K5[Kustomize: trivy<br/>helmCharts: trivy-operator v0.31.0]
            K6[Kustomize: kyverno<br/>helmCharts: kyverno v3.5.2]
        end
    end

    subgraph K8s [Kubernetes Resources]
        direction TB

        subgraph Workloads [Running Workloads]
            DS1[DaemonSet: cilium-agent]
            STS1[StatefulSet: vault-0]
            DEP1[Deployment: argocd-server]

            DS2[DaemonSet: fluent-bit]
            STS2[StatefulSet: loki]
            STS3[StatefulSet: prometheus-prometheus]
            DEP2[Deployment: prometheus-grafana]

            DEP3[Deployment: argo-workflows-server]
            DEP4[Deployment: argo-workflows-controller]
            DEP5[Deployment: trivy-operator]
            DEP6[Deployment: kyverno-admission-controller]
        end
    end

    H1 -->|Deployed via Taskfile| DS1
    H2 -->|Deployed via Taskfile| STS1
    H3 -->|Deployed via Taskfile| DEP1

    DEP1 -->|Manages| APP1
    DEP1 -->|Manages| APP2
    DEP1 -->|Manages| APP3
    DEP1 -->|Manages| APP4
    DEP1 -->|Manages| APP5
    DEP1 -->|Manages| APP6

    APP1 -->|Builds| K1
    APP2 -->|Builds| K2
    APP3 -->|Builds| K3
    APP4 -->|Builds| K4
    APP5 -->|Builds| K5
    APP6 -->|Builds| K6

    K1 -->|Renders Helm + Applies| DS2
    K2 -->|Renders Helm + Applies| STS2
    K3 -->|Renders Helm + Applies| STS3
    K3 -->|Renders Helm + Applies| DEP2
    K4 -->|Renders Helm + Applies| STS4
    K5 -->|Renders Helm + Applies| DEP3
    K6 -->|Renders Helm + Applies| DEP4
```

## 3. Node Pools and Workload Deployment

Within the Hub cluster, nodes are segmented into logical "Node Pools" using
labels to isolate workloads. This classification is the basis for future
scheduling rules with `tolerations` and `affinity`.

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

## 3. Certificate Management Flow

This flow shows how a Gateway resource automatically obtains a TLS certificate
via cert-manager annotation.

```mermaid
sequenceDiagram
    participant GW as Gateway Resource
    participant CM as cert-manager
    participant CI as ClusterIssuer
    participant CAS as CA Secret
    participant FinalTLS as TLS Certificate Secret

    GW->>+CM: 1. Requests certificate via annotation
    Note over GW,CM: cert-manager.io/cluster-issuer: ca-issuer
    CM->>+CI: 2. Reads the ClusterIssuer configuration
    CI-->>-CM: spec.ca.secretName: idp-demo-ca-secret
    CM->>+CAS: 3. Loads the root CA from the Secret
    CAS-->>-CM: CA private key and certificate
    CM-->>CM: 4. Signs wildcard certificate (*.127-0-0-1.sslip.io)
    CM->>+FinalTLS: 5. Creates Certificate Secret (idp-wildcard-cert)
    FinalTLS-->>-GW: 6. Referenced in Gateway spec.listeners.tls
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

This diagram details how metrics and logs are collected, processed, and visualized on
the platform.

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

This diagram illustrates how the Trivy operator scans cluster workloads for
vulnerabilities.

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

This diagram explains the "App of Apps" pattern. The `ApplicationSet` resources in
ArgoCD monitor directories in Git. When they find subdirectories that match their
generator, they automatically create child `Application` resources, one for each
stack component.

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

## 8. Gateway API Service Exposure

This diagram shows how services are exposed via Gateway API with wildcard TLS
and sslip.io DNS (zero configuration required).

```mermaid
graph TB
    subgraph External Access
        Browser[Browser: https://grafana.127-0-0-1.sslip.io]
    end

    subgraph Gateway API Layer - Namespace: kube-system
        Gateway[Gateway: idp-gateway<br/>Listener: HTTPS:443<br/>TLS: idp-wildcard-cert]
        Cert[Certificate: idp-wildcard-cert<br/>*.127-0-0-1.sslip.io<br/>Issuer: ca-issuer]
    end

    subgraph HTTPRoutes - Distributed
        HR1[HTTPRoute: argocd<br/>argocd.127-0-0-1.sslip.io]
        HR2[HTTPRoute: grafana<br/>grafana.127-0-0-1.sslip.io]
        HR3[HTTPRoute: vault<br/>vault.127-0-0-1.sslip.io]
        HR4[HTTPRoute: workflows<br/>workflows.127-0-0-1.sslip.io]
        HR5[HTTPRoute: sonarqube<br/>sonarqube.127-0-0-1.sslip.io]
    end

    subgraph Backend Services
        S1[argocd-server:80]
        S2[prometheus-grafana:80]
        S3[vault:8200]
        S4[argo-workflows-server:2746]
        S5[sonarqube-sonarqube:9000]
    end

    Browser -->|HTTPS Request| Gateway
    Gateway -->|Routes by hostname| HR1
    Gateway -->|Routes by hostname| HR2
    Gateway -->|Routes by hostname| HR3
    Gateway -->|Routes by hostname| HR4
    Gateway -->|Routes by hostname| HR5

    HR1 --> S1
    HR2 --> S2
    HR3 --> S3
    HR4 --> S4
    HR5 --> S5

    Cert -.->|Provides TLS| Gateway
```

## 9. Control Loop Overview

This diagram illustrates the continuous, cross-reconciling control loops between
the core GitOps components, forming the heart of the "Platform as a System."
Each component watches the Kubernetes API server for changes and acts to align the
cluster's actual state with the desired state defined in Git, policies, or
external secret stores.

```mermaid
graph LR
    K8sApi[Kubernetes API Server]

    subgraph GitOps
        ArgoCD[ArgoCD]
    end

    subgraph Policy
        Kyverno[Kyverno]
    end

    subgraph Secrets
        ESO[External Secrets Operator]
    end

    ArgoCD <-->|Reconciles Git State| K8sApi
    Kyverno <-->|Validates & Mutates Resources| K8sApi
    ESO <-->|Syncs External Secrets| K8sApi
```
