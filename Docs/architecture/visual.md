# IDP Visual Architecture

This document describes the platform's architecture, its workflows, and its
execution environment through diagrams.

## 1. General Architecture and GitOps Flow

This diagram shows the high-level view of the workflow, from the definition in a Git
repository to the deployment and operation of the components within the Kubernetes
cluster.

```d2
direction: right

GitRepo: "Git Repository"

K8sCluster: {
  label: "Kubernetes Cluster"

  Core: {
    label: "Core Infrastructure"
    Cilium
    CertManager: "Cert-Manager"
    Vault
    ESO: "External Secrets Operator"
  }

  Engines: {
    label: "GitOps and Policy Engine"
    ArgoCD
    Kyverno
    PolicyReporter: "Policy Reporter"
  }

  AppStacks: {
    label: "Application Stacks"
    Observability: {
      label: "Observability"
      Prometheus
      Grafana
      Loki
      FluentBit: "Fluent-bit"
    }
    CICD: {
      label: "CI/CD"
      Workflows: "Argo Workflows"
      SonarQube
    }
    Security: {
      label: "Security"
      Trivy: "Trivy Operator"
    }
  }

  K8sApi: "Kubernetes API Server"
}

GitRepo -> K8sCluster.Engines.ArgoCD: "Defines State"
K8sCluster.Engines.ArgoCD -> K8sCluster.AppStacks: "Applies Manifests"
K8sCluster.Engines.ArgoCD -> K8sCluster.K8sApi: "Creates Resources"
K8sCluster.K8sApi -> K8sCluster.Engines.Kyverno: "Validates Requests"
K8sCluster.Engines.Kyverno -> K8sCluster.K8sApi: "Enforces Policies"
K8sCluster.Engines.Kyverno -> K8sCluster.Engines.PolicyReporter: "PolicyReports"
K8sCluster.Core.Vault -> K8sCluster.Core.ESO: "Secrets"
K8sCluster.Core.ESO -> K8sCluster.K8sApi: "Syncs"
K8sCluster.AppStacks.Observability.FluentBit -> K8sCluster.AppStacks.Observability.Loki: "Logs"
K8sCluster.AppStacks.Observability.Prometheus -> K8sCluster.AppStacks.Observability.Grafana: "Metrics"
K8sCluster.AppStacks.Observability.Loki -> K8sCluster.AppStacks.Observability.Grafana: "Logs"
K8sCluster.AppStacks.CICD.Workflows -> K8sCluster.AppStacks.CICD.SonarQube: "Analysis"
K8sCluster.AppStacks.Security.Trivy -> K8sCluster.K8sApi: "Scans"
K8sCluster.Core.CertManager -> K8sCluster.K8sApi: "Certificates"
```

## 2. Helm to Pods Deployment Flow

This diagram shows the complete deployment chain from Helm charts to running pods,
illustrating how different layers (Bootstrap, GitOps) interact.

```d2
direction: down

Bootstrap: {
  label: "Bootstrap Layer - IT/"
  H1: "Helm: cilium v1.18.2"
  H2: "Helm: vault v0.31.0"
  H3: "Helm: argocd v8.6.0"
  H4: "Helm: cert-manager v1.19.0"
  H5: "Helm: external-secrets v0.20.2"
}

GitOps: {
  label: "GitOps Layer - K8s/"
  Apps: {
    APP1: "observability-fluent-bit"
    APP2: "observability-loki"
    APP3: "observability-kube-prometheus-stack"
    APP4: "cicd-argo-workflows"
    APP5: "security-trivy"
    APP6: "platform-policies"
  }
}

K8s: {
  label: "Kubernetes Resources"
  DS1: "DaemonSet: cilium-agent"
  STS1: "StatefulSet: vault-0"
  DEP1: "Deployment: argocd-server"
  DS2: "DaemonSet: fluent-bit"
  STS2: "StatefulSet: loki"
  STS3: "StatefulSet: prometheus"
  DEP2: "Deployment: grafana"
  DEP3: "Deployment: argo-workflows-server"
  DEP4: "Deployment: argo-workflows-controller"
  DEP5: "Deployment: trivy-operator"
  DEP6: "Deployment: kyverno-admission-controller"
}

Bootstrap.H1 -> K8s.DS1: "task deploy"
Bootstrap.H2 -> K8s.STS1: "task deploy"
Bootstrap.H3 -> K8s.DEP1: "task deploy"

K8s.DEP1 -> GitOps.Apps.APP1: "manages"
K8s.DEP1 -> GitOps.Apps.APP2
K8s.DEP1 -> GitOps.Apps.APP3
K8s.DEP1 -> GitOps.Apps.APP4
K8s.DEP1 -> GitOps.Apps.APP5
K8s.DEP1 -> GitOps.Apps.APP6

GitOps.Apps.APP1 -> K8s.DS2
GitOps.Apps.APP2 -> K8s.STS2
GitOps.Apps.APP3 -> K8s.STS3
GitOps.Apps.APP3 -> K8s.DEP2
GitOps.Apps.APP4 -> K8s.DEP3
GitOps.Apps.APP5 -> K8s.DEP5
GitOps.Apps.APP6 -> K8s.DEP6
```

## 3. Node Pools and Workload Deployment

Within the Hub cluster, nodes are segmented into logical "Node Pools" using
labels to isolate workloads. This classification is the basis for future
scheduling rules with `tolerations` and `affinity`.

```d2
direction: right

Cluster: {
  label: "IDP Hub Cluster - k3d-idp-demo"
  Infra: "Node Pool: IT Infrastructure\nagent-0 (node-role=it-infra)"
  Apps: "Node Pool: GitOps Workloads\nagent-1 (node-role=k8s-workloads)"
  CP: "Node Pool: Control Plane\nserver-0"
}

Platform: {
  Argo: ArgoCD
  Vault: Vault
  Prom: Prometheus
  Kyv: Kyverno
}

AppWorkloads: {
  Workflows: "Argo Workflows"
  Sonar: SonarQube
}

DS: {
  Cilium: "Cilium Agent"
  Fluent: "Fluent-bit"
  NodeExp: "Node Exporter"
}

Platform.Argo -> Cluster.Infra: "scheduled on"
Platform.Vault -> Cluster.Infra
Platform.Prom -> Cluster.Infra
Platform.Kyv -> Cluster.Infra
AppWorkloads.Workflows -> Cluster.Apps: "scheduled on"
AppWorkloads.Sonar -> Cluster.Apps
DS.Cilium -> Cluster.CP
DS.Cilium -> Cluster.Infra
DS.Cilium -> Cluster.Apps
DS.Fluent -> Cluster.CP
DS.Fluent -> Cluster.Infra
DS.Fluent -> Cluster.Apps
DS.NodeExp -> Cluster.CP
DS.NodeExp -> Cluster.Infra
DS.NodeExp -> Cluster.Apps
```

## 3. Certificate Management Flow

This flow shows how a Gateway resource automatically obtains a TLS certificate
via cert-manager annotation.

```d2
shape: sequence_diagram
GW: Gateway Resource
CM: cert-manager
CI: ClusterIssuer
CAS: CA Secret
TLS: TLS Certificate Secret

GW -> CM: Requests certificate (annotation\ncert-manager.io/cluster-issuer: ca-issuer)
CM -> CI: Read ClusterIssuer
CI -> CM: ca.secretName: idp-demo-ca-secret
CM -> CAS: Load root CA
CAS -> CM: CA key + cert
CM -> TLS: Create idp-wildcard-cert (*.nip.io)
TLS -> GW: Referenced in listeners.tls
```

## 4. Secret Management Flow

This flow details how an application securely consumes a secret from Vault
without having direct credentials.

```d2
shape: sequence_diagram
App: Application Pod
K8S: Kubernetes Secret
ES: ExternalSecret CR
ESO: External Secrets Operator
SS: SecretStore
Vault

App -> K8S: Needs Secret
K8S -> App: Not found / outdated
ESO -> ES: Watch ExternalSecret
ES -> ESO: secretStoreRef: vault-*
ESO -> SS: Read SecretStore (vault, k8s auth)
SS -> ESO: Provider config
ESO -> Vault: Request secret
Vault -> ESO: Secret data
ESO -> K8S: Create/Update Secret
K8S -> App: Mounted in Pod
```

## 5. Observability Data Flow

This diagram details how metrics and logs are collected, processed, and visualized on
the platform.

```d2
direction: right

Nodes: {
  App: "App Pod"
  Kubelet
  NodeExporter
  LogFiles: "Container Logs"
}

Obs: {
  Prom: Prometheus
  Loki
  Graf: Grafana
  KSM: "Kube-State-Metrics"
  FB: "Fluent-bit"
}

Nodes.App -> Nodes.LogFiles: "Logs"
Nodes.App -> Obs.Prom: "Metrics"
Nodes.Kubelet -> Obs.Prom: "Metrics"
Nodes.LogFiles -> Obs.FB: "Tailed"
Obs.FB -> Obs.Loki: "Forwards"
Nodes.NodeExporter -> Obs.Prom: "Node metrics"
Obs.KSM -> Obs.Prom: "Cluster metrics"
Obs.Prom -> Obs.Graf: "Datasource"
Obs.Loki -> Obs.Graf: "Datasource"
```

## 6. Security Scanning Flow with Trivy

This diagram illustrates how the Trivy operator scans cluster workloads for
vulnerabilities.

```d2
shape: sequence_diagram
User: User/ArgoCD
K8s: Kubernetes API
TrivyOp: Trivy Operator
Workload: Deployment/Pod
Report: VulnerabilityReport

User -> K8s: Create/Update Workload
K8s -> TrivyOp: Watch changes
TrivyOp -> Workload: Discover images
TrivyOp -> TrivyOp: Scan images
TrivyOp -> K8s: Create/Update VulnerabilityReport
K8s -> Report: Store CRD
```

## 7. GitOps Structure with ApplicationSets

This diagram explains the "App of Apps" pattern. The `ApplicationSet` resources in
ArgoCD monitor directories in Git. When they find subdirectories that match their
generator, they automatically create child `Application` resources, one for each
stack component.

```d2
direction: right

Git: {
  label: "Git Repository"
  K8sDir: "K8s/ Directory"
  Obs: "observability/"
  Sec: "security/"
  CiCd: "cicd/"
}

Argo: {
  label: "ArgoCD"
  ASObs: "ApplicationSet observability"
  ASSec: "ApplicationSet security"
  ASCi: "ApplicationSet cicd"
  AppProm: "App: obs-prometheus"
  AppGraf: "App: obs-grafana"
  AppLoki: "App: obs-loki"
  AppTrivy: "App: sec-trivy"
}

Git.K8sDir -> Argo.ASObs: Monitored
Git.K8sDir -> Argo.ASSec: Monitored
Git.K8sDir -> Argo.ASCi: Monitored
Argo.ASObs -> Argo.AppProm: Generates
Argo.ASObs -> Argo.AppGraf
Argo.ASObs -> Argo.AppLoki
Argo.ASSec -> Argo.AppTrivy
```

## 8. Gateway API Service Exposure

This diagram shows how services are exposed via Gateway API with wildcard TLS
and sslip.io DNS (zero configuration required).

```d2
direction: down

External: {
  Browser: "Browser: https://grafana.<ip>.nip.io"
}

GatewayNS: {
  label: "Gateway API Layer - kube-system"
  Gateway: "Gateway: idp-gateway\nHTTPS:443\nTLS: idp-wildcard-cert"
  Cert: "Certificate: idp-wildcard-cert\n*.nip.io\nIssuer: ca-issuer"
}

Routes: {
  label: "HTTPRoutes"
  HR1: "argocd"
  HR2: "grafana"
  HR3: "vault"
  HR4: "workflows"
  HR5: "sonarqube"
}

Backends: {
  S1: "argocd-server:80"
  S2: "prometheus-grafana:80"
  S3: "vault:8200"
  S4: "argo-workflows-server:2746"
  S5: "sonarqube:9000"
}

External.Browser -> GatewayNS.Gateway: HTTPS
GatewayNS.Gateway -> Routes.HR1: hostname route
GatewayNS.Gateway -> Routes.HR2
GatewayNS.Gateway -> Routes.HR3
GatewayNS.Gateway -> Routes.HR4
GatewayNS.Gateway -> Routes.HR5
Routes.HR1 -> Backends.S1
Routes.HR2 -> Backends.S2
Routes.HR3 -> Backends.S3
Routes.HR4 -> Backends.S4
Routes.HR5 -> Backends.S5
GatewayNS.Cert -> GatewayNS.Gateway: TLS
```

## 9. Control Loop Overview

This diagram illustrates the continuous, cross-reconciling control loops between
the core GitOps components, forming the heart of the "Platform as a System."
Each component watches the Kubernetes API server for changes and acts to align the
cluster's actual state with the desired state defined in Git, policies, or
external secret stores.

```d2
direction: right

K8s: "Kubernetes API Server"
GitOps: {
  Argo: ArgoCD
}
Policy: {
  Kyverno
}
Secrets: {
  ESO: "External Secrets Operator"
}

GitOps.Argo <-> K8s: "Reconciles Git State"
Policy.Kyverno <-> K8s: "Validates & Mutates"
Secrets.ESO <-> K8s: "Syncs Secrets"
```
