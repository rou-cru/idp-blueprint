# IDP Blueprint Documentation

**IDP Blueprint** is an Internal Developer Platform reference architecture designed for modern cloud-native environments. This comprehensive platform engineering solution provides a complete stack including GitOps, observability, security, and policy enforcement, deployable for development, testing, and production environments. Also follows FinOps tagging practices to be prepared in case you add FinOps to the development cycle.

---

## IDP Blueprint Architecture

This diagram represents the IDP Blueprint as a **modular, treemap-style architecture** where:

- **Position** indicates semantic relationships and dependencies
- **Size** reflects importance and surface area of impact
- **Color** groups components by domain concern and shows transversality
- **Adjacency** indicates collaboration and complementarity

Components marked as *[conceptual]* are planned but not yet implemented.

```d2
direction: right

classes: {
  infra: { style: { fill: "#263238"; font-color: "#ffffff"; stroke: "#37474f" } }
  network: { style: { fill: "#006064"; font-color: "#ffffff"; stroke: "#00838f" } }
  gitops: { style: { fill: "#1b5e20"; font-color: "#ffffff"; stroke: "#2e7d32"; stroke-width: 3 } }
  platform: { style: { fill: "#4a148c"; font-color: "#ffffff"; stroke: "#6a1b9a" } }
  observe: { style: { fill: "#e65100"; font-color: "#ffffff"; stroke: "#ef6c00" } }
  policy: { style: { fill: "#b71c1c"; font-color: "#ffffff"; stroke: "#c62828" } }
  quality: { style: { fill: "#f57f17"; font-color: "#000000"; stroke: "#f9a825" } }
  devexp: { style: { fill: "#0d47a1"; font-color: "#ffffff"; stroke: "#1565c0" } }
  conceptual: { style: { fill: "#e0e0e0"; font-color: "#757575"; stroke: "#9e9e9e"; stroke-dash: 3 } }
}

IDP Blueprint Architecture: {
  grid-rows: 12
  grid-columns: 12
  grid-gap: 4

  # Row 0-1: Software Catalog (conceptual, spans 2 rows)
  0,0: { label: "Software Catalog\n[conceptual]"; class: conceptual; height: 100 }
  0,1: { label: ""; class: conceptual; style.opacity: 0 }
  0,2: { label: ""; class: conceptual; style.opacity: 0 }
  0,3: { label: ""; class: conceptual; style.opacity: 0 }
  0,4: { label: ""; class: conceptual; style.opacity: 0 }
  0,5: { label: ""; class: conceptual; style.opacity: 0 }
  0,6: { label: ""; class: conceptual; style.opacity: 0 }
  0,7: { label: ""; class: conceptual; style.opacity: 0 }
  0,8: { label: ""; class: conceptual; style.opacity: 0 }
  0,9: { label: ""; class: conceptual; style.opacity: 0 }
  0,10: { label: ""; class: conceptual; style.opacity: 0 }
  0,11: { label: ""; class: conceptual; style.opacity: 0 }

  # Row 2: Developer UIs
  2,0: { label: "ArgoCD"; class: devexp }
  2,1: { label: "Grafana"; class: devexp }
  2,2: { label: "Vault"; class: devexp }
  2,3: { label: "SonarQube"; class: quality }
  2,4: { label: "Kyverno"; class: policy }
  2,5: { label: ""; style.opacity: 0 }
  2,6: { label: ""; style.opacity: 0 }
  2,7: { label: ""; style.opacity: 0 }
  2,8: { label: ""; style.opacity: 0 }
  2,9: { label: ""; style.opacity: 0 }
  2,10: { label: ""; style.opacity: 0 }
  2,11: { label: ""; style.opacity: 0 }

  # Row 3-4: Observability (spans 2 rows, shows transversality by repetition across columns)
  3,0: { label: "Prometheus"; class: observe; height: 100 }
  3,1: { label: "Grafana"; class: observe; height: 100 }
  3,2: { label: "Loki"; class: observe; height: 100 }
  3,3: { label: "Fluent-bit"; class: observe; height: 100 }

  # Row 3-4: Policy & Security (same row level as Observability)
  3,4: { label: "Kyverno"; class: policy; height: 100 }
  3,5: { label: "Trivy"; class: policy; height: 100 }
  3,6: { label: "Reporter"; class: policy; height: 100 }

  # Row 3-4: Quality & CI/CD
  3,7: { label: "Workflows"; class: quality; height: 100 }
  3,8: { label: "SonarQube"; class: quality; height: 100 }
  3,9: { label: ""; style.opacity: 0 }
  3,10: { label: ""; style.opacity: 0 }
  3,11: { label: ""; style.opacity: 0 }

  # Row 5-6: GitOps Engine (spans 2 rows, full width)
  5,0: { label: "ArgoCD\nCore"; class: gitops; height: 100 }
  5,1: { label: ""; class: gitops; style.opacity: 0 }
  5,2: { label: ""; class: gitops; style.opacity: 0 }
  5,3: { label: "Application\nSets"; class: gitops; height: 100 }
  5,4: { label: ""; class: gitops; style.opacity: 0 }
  5,5: { label: ""; class: gitops; style.opacity: 0 }
  5,6: { label: "Sync\nEngine"; class: gitops; height: 100 }
  5,7: { label: ""; class: gitops; style.opacity: 0 }
  5,8: { label: ""; class: gitops; style.opacity: 0 }
  5,9: { label: ""; class: gitops; style.opacity: 0 }
  5,10: { label: ""; class: gitops; style.opacity: 0 }
  5,11: { label: ""; class: gitops; style.opacity: 0 }

  # Row 7: Platform Services
  7,0: { label: "Vault"; class: platform }
  7,1: { label: "KV Store"; class: platform }
  7,2: { label: "PKI"; class: platform }
  7,3: { label: "External\nSecrets"; class: platform }
  7,4: { label: "Sync"; class: platform }
  7,5: { label: "Cert\nManager"; class: platform }
  7,6: { label: "Issuers"; class: platform }
  7,7: { label: "Gateway\nAPI"; class: platform }
  7,8: { label: "HTTPRoute"; class: platform }
  7,9: { label: ""; style.opacity: 0 }
  7,10: { label: ""; style.opacity: 0 }
  7,11: { label: ""; style.opacity: 0 }

  # Row 8-9: Cilium (spans 2 rows)
  8,0: { label: "CNI"; class: network; height: 100 }
  8,1: { label: "Pod\nNetwork"; class: network; height: 100 }
  8,2: { label: "IPAM"; class: network; height: 100 }
  8,3: { label: "Service\nMesh"; class: network; height: 100 }
  8,4: { label: "L7 Proxy"; class: network; height: 100 }
  8,5: { label: "mTLS"; class: network; height: 100 }
  8,6: { label: "Gateway"; class: network; height: 100 }
  8,7: { label: "Load\nBalancer"; class: network; height: 100 }
  8,8: { label: "Network\nPolicy"; class: network; height: 100 }
  8,9: { label: "L3/L4/L7"; class: network; height: 100 }
  8,10: { label: ""; class: network; style.opacity: 0 }
  8,11: { label: ""; class: network; style.opacity: 0 }

  # Row 10: Kubernetes
  10,0: { label: "API\nServer"; class: infra }
  10,1: { label: "Scheduler"; class: infra }
  10,2: { label: "Controller"; class: infra }
  10,3: { label: "etcd"; class: infra }
  10,4: { label: "Kubelet"; class: infra }
  10,5: { label: "Pods"; class: infra }
  10,6: { label: ""; class: infra; style.opacity: 0 }
  10,7: { label: ""; class: infra; style.opacity: 0 }
  10,8: { label: ""; class: infra; style.opacity: 0 }
  10,9: { label: ""; class: infra; style.opacity: 0 }
  10,10: { label: ""; class: infra; style.opacity: 0 }
  10,11: { label: ""; class: infra; style.opacity: 0 }

  # Row 11: Container Runtime
  11,0: { label: "K3d"; class: infra }
  11,1: { label: "Containerd"; class: infra }
  11,2: { label: "Storage"; class: infra }
  11,3: { label: "Network"; class: infra }
  11,4: { label: ""; class: infra; style.opacity: 0 }
  11,5: { label: ""; class: infra; style.opacity: 0 }
  11,6: { label: ""; class: infra; style.opacity: 0 }
  11,7: { label: ""; class: infra; style.opacity: 0 }
  11,8: { label: ""; class: infra; style.opacity: 0 }
  11,9: { label: ""; class: infra; style.opacity: 0 }
  11,10: { label: ""; class: infra; style.opacity: 0 }
  11,11: { label: ""; class: infra; style.opacity: 0 }
}
```

### Architecture Principles

**Visual Grammar:**

- **Position**: Elements lower in the diagram are dependencies of those above
- **Size**: Larger blocks (multi-row) indicate greater surface area of impact
- **Color**: Groups components by domain concern - same color = related functionality
- **Transversality**: Shown by color repetition across rows (e.g., orange observe blocks span multiple columns)

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
