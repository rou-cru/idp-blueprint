# IDP Blueprint Documentation

**IDP Blueprint** is an Internal Developer Platform reference architecture designed for modern cloud-native environments. This comprehensive platform engineering solution provides a complete stack including GitOps, observability, security, and policy enforcement, deployable for development, testing, and production environments. Also follows FinOps tagging practices to be prepared in case you add FinOps to the development cycle.

---

## IDP Blueprint Architecture

This diagram represents the IDP Blueprint as a **modular, treemap-style architecture** where:

- **Position** indicates semantic relationships and dependencies
- **Size** reflects importance and surface area of impact
- **Nesting** shows containment and provision
- **Color** groups components by domain concern
- **Adjacency** indicates collaboration and complementarity

Components marked as *[conceptual]* are planned but not yet implemented.

```d2
direction: down

classes: {
  infra: { style: { fill: "#1a237e"; font-color: "#ffffff"; stroke: "#0d47a1" } }
  runtime: { style: { fill: "#01579b"; font-color: "#ffffff"; stroke: "#0277bd" } }
  network: { style: { fill: "#006064"; font-color: "#ffffff"; stroke: "#00838f" } }
  platform: { style: { fill: "#4a148c"; font-color: "#ffffff"; stroke: "#6a1b9a" } }
  secrets: { style: { fill: "#311b92"; font-color: "#ffffff"; stroke: "#512da8" } }
  gitops: { style: { fill: "#1b5e20"; font-color: "#ffffff"; stroke: "#2e7d32"; stroke-width: 3 } }
  observe: { style: { fill: "#e65100"; font-color: "#ffffff"; stroke: "#ef6c00" } }
  policy: { style: { fill: "#b71c1c"; font-color: "#ffffff"; stroke: "#c62828" } }
  security: { style: { fill: "#880e4f"; font-color: "#ffffff"; stroke: "#ad1457" } }
  quality: { style: { fill: "#f57f17"; font-color: "#000000"; stroke: "#f9a825" } }
  cicd: { style: { fill: "#ff6f00"; font-color: "#ffffff"; stroke: "#ff8f00" } }
  devexp: { style: { fill: "#0d47a1"; font-color: "#ffffff"; stroke: "#1565c0" } }
  conceptual: { style: { fill: "#e0e0e0"; font-color: "#757575"; stroke: "#9e9e9e"; stroke-dash: 3 } }
  context: { style: { fill: "#fafafa"; font-color: "#424242"; stroke: "#bdbdbd" } }
  taxonomy: { style: { fill: "#f5f5f5"; font-color: "#616161"; stroke: "#9e9e9e"; font-size: 12 } }
}

GitRepo: {
  class: context
  label: "Git Repository\nSource of Truth"

  RepoStructure: {
    shape: text
    label: "├─ K8s/\n├─ IT/\n├─ Policies/"
    style: { font-size: 11; font-family: mono }
  }
}

Architecture: {
  label: "IDP Blueprint - Modular Architecture"

  DevExpPlane: {
    class: devexp
    label: "Developer Experience Plane"

    Catalog: {
      class: conceptual
      label: "Software Catalog / Service Registry\n[conceptual - Backstage]"
    }

    Interfaces: {
      class: devexp
      label: "Developer Interfaces"

      ArgoUI: { label: "ArgoCD UI" }
      GrafanaUI: { label: "Grafana" }
      VaultUI: { label: "Vault UI" }
      SonarUI: { label: "SonarQube" }
      KyvernoUI: { label: "Kyverno" }
    }
  }

  Capabilities: {
    label: "Platform Capabilities"

    Observability: {
      class: observe
      label: "Observability\n(Transversal)"

      Prometheus: { label: "Prometheus" }
      Grafana: { label: "Grafana" }
      Loki: { label: "Loki" }
      FluentBit: { label: "Fluent-bit" }
      Alertmanager: { label: "Alertmanager" }
    }

    PolicySecurity: {
      label: "Policy, Security & Quality"

      Kyverno: {
        class: policy
        label: "Kyverno\nPolicy Engine"
      }
      Trivy: {
        class: security
        label: "Trivy\nVuln Scanner"
      }
      PolicyReporter: {
        class: policy
        label: "Policy\nReporter"
      }
      SonarQube: {
        class: quality
        label: "SonarQube\nQuality"
      }
    }

    CICD: {
      class: cicd
      label: "CI/CD & Workflows"

      Workflows: { label: "Argo\nWorkflows" }
    }
  }

  GitOpsEngine: {
    class: gitops
    label: "GitOps Orchestration Engine"

    ArgoCDCore: { label: "ArgoCD Core\nCD Controller" }
    AppSets: { label: "ApplicationSets\nMulti-tenant" }
    SyncEngine: { label: "Sync & Health\nStatus Engine" }

    Note: {
      shape: text
      label: "▼ reconciles everything below"
      style: { font-size: 14; font-color: "#2e7d32"; bold: true }
    }
  }

  PlatformServices: {
    label: "Platform Infrastructure Services"

    Vault: {
      class: secrets
      label: "Vault"

      VaultKV: { label: "KV Store" }
      VaultPKI: { label: "PKI" }
      VaultDynamic: { label: "Dynamic\nSecrets" }
    }

    ExternalSecrets: {
      class: platform
      label: "External Secrets\nOperator"

      ESO: { label: "Sync Loop" }
    }

    CertManager: {
      class: platform
      label: "Cert Manager"

      Issuers: { label: "Issuers\nACME/CA" }
    }

    GatewayAPI: {
      class: platform
      label: "Gateway API\n& Ingress"

      Gateway: { label: "HTTPRoute\nTLS" }
    }
  }

  CiliumStack: {
    class: network
    label: "Cilium - Converged Network Stack"

    CNI: { label: "CNI Plugin\nPod Network\nIPAM" }
    ServiceMesh: { label: "Service Mesh\nL7 Proxy\nmTLS" }
    GatewayLB: { label: "Gateway\nLoad Balancer" }
    NetworkPolicy: { label: "Network Policy\nL3/L4/L7" }

    eBPF: {
      shape: text
      label: "eBPF Datapath (Kernel-level)"
      style: { font-size: 12; font-color: "#00e5ff"; bold: true }
    }
  }

  CiliumNote: {
    shape: text
    label: "[INTERCAMBIABLE: Calico, Flannel, Weave]"
    style: { font-size: 10; font-color: "#00838f"; italic: true }
  }

  Kubernetes: {
    class: runtime
    label: "Kubernetes - Orchestration Runtime"

    ControlPlane: {
      label: "Control Plane"

      APIServer: { label: "API Server" }
      Scheduler: { label: "Scheduler" }
      ControllerMgr: { label: "Controller\nManager" }
      Etcd: { label: "etcd" }
    }

    WorkerNodes: {
      label: "Worker Nodes"

      Kubelet: { label: "Kubelet" }
      KubeProxy: { label: "Kube-proxy" }

      PodsGroup: {
        label: "Pods"

        Pod1: { label: "Pod\nC1\nC2" }
        Pod2: { label: "Pod\nC1" }
        Pod3: { label: "Pod\nC1\nC2" }
      }
    }
  }

  K8sNote: {
    shape: text
    label: "[INTERCAMBIABLE: K3s, Kind, EKS, GKE, AKS, OpenShift]"
    style: { font-size: 10; font-color: "#0277bd"; italic: true }
  }

  Runtime: {
    class: infra
    label: "Container Runtime & Compute Infrastructure"

    K3d: { label: "K3d Cluster" }
    ContainerRuntime: { label: "Docker/\nContainerd" }
    Storage: { label: "Local Storage" }
    Network: { label: "Host Network" }
  }

  RuntimeNote: {
    shape: text
    label: "[INTERCAMBIABLE: Docker, Podman, CRI-O, Cloud VMs, Bare Metal]"
    style: { font-size: 10; font-color: "#1a237e"; italic: true }
  }
}

DeveloperPortal: {
  class: conceptual
  label: "Developer Portal\n[conceptual]"

  Backstage: { label: "Backstage" }
  Templates: { label: "Templates" }
  Docs: { label: "Docs" }
}

Abstractions: {
  class: context
  label: "Abstractions"

  APIs: {
    shape: text
    label: "• Gateway API\n• K8s API\n• CNI\n• Storage CSI"
    style: { font-size: 11 }
  }

  WorkloadSpec: {
    class: conceptual
    label: "Workload Spec\n[Score/OAM]"
  }
}

FinOps: {
  class: context
  label: "FinOps Tagging (Overlay)"

  Tags: {
    shape: text
    label: "owner: platform-team | business-unit: infrastructure | environment: demo\nEnforcement: Kustomize → Kyverno → Prometheus"
    style: { font-size: 10; italic: true }
  }
}

SecurityOverlay: {
  class: context
  label: "Security Posture (Overlay)"

  SecurityFlow: {
    shape: text
    label: "Policy Enforcement ↔ Vuln Scanning ↔ Secrets Mgmt ↔ Cert Lifecycle"
    style: { font-size: 10; italic: true }
  }
}

GitRepo -> Architecture.GitOpsEngine: "feeds"
Architecture.GitOpsEngine -> Architecture.CiliumStack: "reconciles"
Architecture.GitOpsEngine -> Architecture.Kubernetes: "manages"
Architecture.Capabilities.Observability -> Architecture.Kubernetes: "monitors"
Architecture.PlatformServices.Vault -> Architecture.PlatformServices.ExternalSecrets: "secrets"
DeveloperPortal -> Architecture.DevExpPlane: "surfaces"
```

### Architecture Principles

**Visual Grammar:**

- **Position**: Elements lower in the diagram are dependencies of those above
- **Size**: Larger blocks indicate greater surface area of impact
- **Nesting**: Inner blocks are provided/contained by outer blocks
- **Color**: Groups components by domain concern
- **Adjacency**: Side-by-side components collaborate or complement each other

**Interchange Points** - Clear abstraction boundaries for swappable components:

| Component | Interface Contract | Alternatives |
|-----------|-------------------|--------------|
| Container Runtime | K8s CRI | Docker → Podman, CRI-O |
| Kubernetes | K8s API | K3d → Kind, Minikube, EKS, GKE, AKS |
| CNI Provider | CNI Plugin | Cilium → Calico, Flannel, Weave |
| GitOps Engine | Git as Truth | ArgoCD → Flux CD |
| Observability | Metrics/Logs APIs | Prometheus → Datadog, New Relic |
| Developer Portal | Service Catalog | Backstage → Port, Humanitec |

**Transversal Concerns:**

- **GitOps**: Orchestrates all platform and application resources declaratively
- **Observability**: Monitors across all layers from infrastructure to applications
- **FinOps**: Tags propagate through all resources for cost attribution
- **Security**: Policy enforcement, scanning, and secrets management span the entire stack

---

## Choose Your Journey

<div class="grid cards" markdown>

- **Concepts**

    ---

    Learn the platform architecture, design tenets, and control planes that make up the IDP Blueprint.

    [:octicons-arrow-right-24: Explore Concepts](architecture/overview.md)

-   **Get Started**

    ---

    Install, verify and take your first steps with the platform.

    [:octicons-arrow-right-24: Start Building](getting-started/quickstart.md)

-   **Components**

    ---

    Dive into infrastructure, policy, observability and CI/CD components.

    [:octicons-arrow-right-24: Explore Components](components/infrastructure/index.md)

-   **Reference**

    ---

    Access canonical labels, FinOps mapping, resource requirements, and troubleshooting matrices.

    [:octicons-arrow-right-24: View Reference](reference/labels-standard.md)

</div>

---

## Who Is This For?

<div class="grid cards" markdown>

-   **Platform Engineers**

    ---

    Focus on the bootstrap layer, GitOps workflows, and operational guides under *Operate*.

-   **Security & Policy Teams**

    ---

    Review Kyverno, Trivy, and governance references within *Components → Policy & Security*.

-   **Observability & SRE**

    ---

    Jump to *Components → Observability* for dashboards, alerts, and data flow diagrams.

-   **Application Teams**

    ---

    Use the quick-start and CI/CD sections to understand how workloads onboard to the platform.

</div>

---

## Documentation Structure

### [Getting Started](getting-started/overview.md)
Deployment and configuration documentation:

- **[Prerequisites](getting-started/prerequisites.md)** - Infrastructure requirements and system dependencies
- **[Quick Start](getting-started/quickstart.md)** - Rapid deployment procedures
- **[Deployment Guide](getting-started/deployment.md)** - Comprehensive deployment process

- ### Concepts
  - [Platform Overview](architecture/overview.md)
  - [Visual Architecture](architecture/visual.md)
  - [Platform Layers](architecture/infrastructure.md)

- ### How-to Guides
  - [Prerequisites](getting-started/prerequisites.md)
  - [Quick Start](getting-started/quickstart.md)
  - [Deployment Guide](getting-started/deployment.md)
  - [Operations Checklist](reference/resource-requirements.md)
  - [Troubleshooting Playbook](reference/troubleshooting.md)

- ### Platform Operations
  - [Infrastructure Stack](components/infrastructure/index.md)
  - [Policy & Security](components/policy/index.md)
  - [Observability](components/observability/index.md)
  - [CI/CD](components/cicd/index.md)

- ### Reference
  - [Label Standards](reference/labels-standard.md)
  - [FinOps Tags](reference/finops-tags.md)
  - [Contributing](guides/contributing.md)

---

## Platform Technology Stack

Enterprise-grade platform engineering stack with production-ready components:

| Layer | Technologies | Capabilities |
|-------|--------------|--------------|
| **GitOps** | ArgoCD, ApplicationSets | Declarative infrastructure and application lifecycle management |
| **Policy Engine** | Kyverno, Policy Reporter | Policy-as-code enforcement and compliance reporting |
| **Observability** | Prometheus, Grafana, Loki, Fluent-bit | Metrics aggregation, visualization, and centralized logging |
| **Networking** | Cilium CNI | eBPF-based networking, load balancing, and service mesh |
| **Security** | HashiCorp Vault, External Secrets, Trivy | Secrets management and vulnerability scanning |
| **CI/CD** | Argo Workflows, SonarQube | Continuous integration pipelines and code quality analysis |
| **PKI** | Cert-Manager | Automated certificate lifecycle management |

---

## Platform Capabilities

!!! abstract "Production-Ready Platform Engineering"
    Complete platform engineering stack suitable for development, staging, and production environments. Designed for:

    - **Enterprise Architecture** - Evaluate cloud-native technologies in realistic deployment scenarios
    - **Infrastructure Prototyping** - Validate infrastructure changes before production rollout
    - **Team Enablement** - Platform engineering training and knowledge transfer
    - **Policy Validation** - Test and validate policies, workflows, and configurations

!!! example "Automated Deployment"
    ```bash
    task deploy
    ```
    Fully automated deployment orchestration including cluster provisioning, component installation, GitOps synchronization, and validation.

!!! info "Resource Requirements"
    Optimized resource allocation for various deployment scenarios:

    - **Minimum Configuration**: 4 CPU cores, 8GB RAM
    - **Recommended Configuration**: 6 CPU cores, 12GB RAM
    - **Storage Requirements**: ~20GB persistent storage

---

## Getting Started

<div class="grid" markdown>

<div markdown>
### Platform Deployment

Comprehensive deployment documentation for platform engineers.

[Deployment Guide](getting-started/quickstart.md){ .md-button .md-button--primary }
</div>

<div markdown>
### Source Repository

Access source code, documentation, and issue tracking.

[GitHub Repository](https://github.com/rou-cru/idp-blueprint){ .md-button }
</div>

</div>

---

## Support & Resources

For technical support and contributions:

- **Issue Tracking**: [Report bugs or request features](https://github.com/rou-cru/idp-blueprint/issues)
- **Documentation**: [Complete technical documentation](https://rou-cru.github.io/idp-blueprint)
- **Contributing**: See our [Contributing Guide](guides/contributing.md) for development guidelines

---

**IDP Blueprint** is open source software licensed under the [MIT License](https://github.com/rou-cru/idp-blueprint/blob/main/LICENSE).
