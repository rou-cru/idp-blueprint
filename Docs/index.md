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
direction: right

classes: {
  context: { style: { fill: "#fafafa"; font-color: "#424242"; stroke: "#bdbdbd" } }
  infra: { style: { fill: "#263238"; font-color: "#ffffff"; stroke: "#37474f" } }
  network: { style: { fill: "#006064"; font-color: "#ffffff"; stroke: "#00838f" } }
  gitops: { style: { fill: "#1b5e20"; font-color: "#ffffff"; stroke: "#2e7d32"; stroke-width: 2 } }
  platform: { style: { fill: "#4a148c"; font-color: "#ffffff"; stroke: "#6a1b9a" } }
  observe: { style: { fill: "#e65100"; font-color: "#ffffff"; stroke: "#ef6c00" } }
  policy: { style: { fill: "#b71c1c"; font-color: "#ffffff"; stroke: "#c62828" } }
  quality: { style: { fill: "#f57f17"; font-color: "#000000"; stroke: "#f9a825" } }
  cicd: { style: { fill: "#ff6f00"; font-color: "#ffffff"; stroke: "#ff8f00" } }
  devexp: { style: { fill: "#0d47a1"; font-color: "#ffffff"; stroke: "#1565c0" } }
  conceptual: { style: { fill: "#e0e0e0"; font-color: "#757575"; stroke: "#9e9e9e"; stroke-dash: 3 } }
}

# Main 3-column layout
MainGrid: {
  grid-columns: 3
  grid-gap: 16

  # ============================================================================
  # LEFT COLUMN: Context & Source
  # ============================================================================
  LeftContext: {
    class: context
    grid-columns: 1
    grid-gap: 12

    GitRepo: {
      label: "Git Repository\nSource of Truth"
      RepoFiles: { label: "K8s/\nIT/\nPolicies/" }
    }

    Taxonomy: {
      label: "Platform Layers"
      Layer1: { label: "DevExp" }
      Layer2: { label: "Platform" }
      Layer3: { label: "Infrastructure" }
    }
  }

  # ============================================================================
  # MIDDLE COLUMN: Main Architecture (stacked rows)
  # ============================================================================
  Architecture: {
    label: "IDP Blueprint Architecture"
    grid-columns: 1
    grid-gap: 8

    # Row 1: Software Catalog (full width)
    Catalog: {
      class: conceptual
      label: "Software Catalog / Service Registry\n[conceptual - Backstage]"
    }

    # Row 2: Developer Interfaces (5 columns)
    DevInterfaces: {
      grid-columns: 5
      grid-gap: 6

      ArgoUI: { class: devexp; label: "ArgoCD\nUI" }
      GrafanaUI: { class: devexp; label: "Grafana\nUI" }
      VaultUI: { class: devexp; label: "Vault\nUI" }
      SonarUI: { class: quality; label: "SonarQube\nUI" }
      KyvernoUI: { class: policy; label: "Kyverno\nUI" }
    }

    # Row 3: Platform Capabilities (3 major blocks)
    Capabilities: {
      grid-columns: 3
      grid-gap: 6

      Observability: {
        class: observe
        label: "Observability\n(Transversal)"
        Prom: { label: "Prometheus" }
        Graf: { label: "Grafana" }
        Loki: { label: "Loki" }
        Fluent: { label: "Fluent-bit" }
      }

      PolicySec: {
        class: policy
        label: "Policy & Security"
        Kyv: { label: "Kyverno" }
        Triv: { label: "Trivy" }
        Rep: { label: "Reporter" }
      }

      CICD: {
        class: cicd
        label: "CI/CD & Quality"
        Wf: { label: "Argo\nWorkflows" }
        Sonar: { label: "SonarQube" }
      }
    }

    # Row 4: GitOps Engine (full width)
    GitOpsEngine: {
      class: gitops
      label: "ArgoCD - GitOps Orchestration Engine"
      grid-columns: 3
      grid-gap: 8

      Core: { label: "ArgoCD Core\nCD Controller" }
      AppSets: { label: "ApplicationSets\nMulti-tenant" }
      Sync: { label: "Sync & Health\nStatus Engine" }
    }

    # Row 5: Platform Infrastructure Services (4 columns)
    PlatformServices: {
      grid-columns: 4
      grid-gap: 6

      Vault: {
        class: platform
        label: "Vault"
        KV: { label: "KV Store" }
        PKI: { label: "PKI" }
      }

      ExtSecrets: {
        class: platform
        label: "External\nSecrets"
        Sync: { label: "Sync Loop" }
      }

      CertMgr: {
        class: platform
        label: "Cert\nManager"
        Issuers: { label: "Issuers" }
      }

      Gateway: {
        class: platform
        label: "Gateway\nAPI"
        Routes: { label: "HTTPRoute" }
      }
    }

    # Row 6: Cilium Network Stack (full width)
    CiliumStack: {
      class: network
      label: "Cilium - Converged Network Stack"
      grid-columns: 4
      grid-gap: 6

      CNI: { label: "CNI Plugin\nPod Network\nIPAM" }
      Mesh: { label: "Service Mesh\nL7 Proxy\nmTLS" }
      GW: { label: "Gateway\nLoad Balancer" }
      NetPol: { label: "Network Policy\nL3/L4/L7" }
    }

    # Row 7: Kubernetes (full width)
    Kubernetes: {
      class: infra
      label: "Kubernetes - Orchestration Runtime"
      grid-columns: 6
      grid-gap: 4

      API: { label: "API\nServer" }
      Sched: { label: "Scheduler" }
      Ctrl: { label: "Controller\nManager" }
      Etcd: { label: "etcd" }
      Kubelet: { label: "Kubelet" }
      Pods: { label: "Pods" }
    }

    # Row 8: Container Runtime (full width)
    Runtime: {
      class: infra
      label: "Container Runtime & Compute Infrastructure"
      grid-columns: 4
      grid-gap: 6

      K3d: { label: "K3d Cluster" }
      Docker: { label: "Docker/\nContainerd" }
      Storage: { label: "Local\nStorage" }
      Network: { label: "Host\nNetwork" }
    }
  }

  # ============================================================================
  # RIGHT COLUMN: Portal & Abstractions
  # ============================================================================
  RightContext: {
    class: context
    grid-columns: 1
    grid-gap: 12

    DevPortal: {
      class: conceptual
      label: "Developer Portal\n[conceptual]"
      Backstage: { label: "Backstage" }
      Templates: { label: "Templates" }
      Docs: { label: "Docs" }
    }

    Abstractions: {
      label: "Abstractions\n& APIs"
      GW: { label: "Gateway API" }
      K8s: { label: "K8s API" }
      CNI: { label: "CNI" }
      CSI: { label: "Storage CSI" }
    }
  }
}

# Bottom row: Cross-cutting concerns
CrossCutting: {
  grid-columns: 3
  grid-gap: 12

  FinOps: {
    class: context
    label: "FinOps Tagging Layer"
    Tags: { label: "owner | business-unit | environment\nKustomize → Kyverno → Prometheus" }
  }

  Security: {
    class: context
    label: "Security Posture"
    Flow: { label: "Policy ↔ Scanning ↔ Secrets ↔ Certs" }
  }

  Interchange: {
    class: context
    label: "Interchange Points"
    Points: { label: "Runtime | K8s | CNI | GitOps\nObservability | Portal" }
  }
}

# Key Relationships
MainGrid.LeftContext.GitRepo -> MainGrid.Architecture.GitOpsEngine: "feeds"
MainGrid.Architecture.GitOpsEngine -> MainGrid.Architecture.CiliumStack: "reconciles"
MainGrid.Architecture.GitOpsEngine -> MainGrid.Architecture.Kubernetes: "manages"
MainGrid.Architecture.Capabilities.Observability -> MainGrid.Architecture.Kubernetes: "monitors"
MainGrid.Architecture.PlatformServices.Vault -> MainGrid.Architecture.PlatformServices.ExtSecrets: "secrets"
MainGrid.RightContext.DevPortal -> MainGrid.Architecture.Catalog: "surfaces"
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
