# IDP Blueprint Documentation

**IDP Blueprint** is an Internal Developer Platform reference architecture designed for modern cloud-native environments. This comprehensive platform engineering solution provides a complete stack including GitOps, observability, security, and policy enforcement, deployable for development, testing, and production environments. Also follows FinOps tagging practices to be prepared in case you add FinOps to the development cycle.

---

## IDP Blueprint Architecture

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
  conceptual: { style: { fill: "#e0e0e0"; font-color: "#757575"; stroke: "#9e9e9e"; stroke-dash: 3 } }
}

IDP Blueprint Architecture: {
  grid-rows: 10
  grid-columns: 10
  grid-gap: 4

  # Row 0: Software Catalog (full width, 2-row height)
  0,0: { label: "Software Catalog [conceptual]"; class: conceptual; width: 2000; height: 120 }

  # Row 2: Observability (transversal - spanning 2 rows)
  2,0: { label: "Prometheus"; class: observe; height: 120 }
  2,1: { label: "Alertmanager"; class: observe; height: 120 }
  2,2: { label: "Grafana"; class: observe; height: 120 }
  2,3: { label: "Loki"; class: observe; height: 120 }
  2,4: { label: "Fluent-bit"; class: observe; height: 120 }

  # Row 2: Policy & Security (transversal - spanning 2 rows)
  2,5: { label: "Kyverno"; class: policy; height: 120 }
  2,6: { label: "Policy\nReporter"; class: policy; height: 120 }
  2,7: { label: "Trivy"; class: policy; height: 120 }

  # Row 2: CI/CD & Quality (transversal - spanning 2 rows)
  2,8: { label: "Argo\nWorkflows"; class: quality; height: 120 }
  2,9: { label: "SonarQube"; class: quality; height: 120 }

  # Row 4: GitOps Engine (2-row height)
  4,0: { label: "ArgoCD"; class: gitops; width: 1000; height: 120 }
  4,5: { label: "Application\nSets"; class: gitops; width: 800; height: 120 }

  # Row 6: Platform Services
  6,0: { label: "Vault"; class: platform }
  6,2: { label: "External\nSecrets"; class: platform }
  6,5: { label: "Cert\nManager"; class: platform }
  6,8: { label: "Gateway\nAPI"; class: platform }

  # Row 7: Cilium (full width, 2-row height)
  7,0: { label: "Cilium"; class: network; width: 2000; height: 120 }

  # Row 9: Kubernetes Infrastructure
  9,0: { label: "API Server"; class: infra }
  9,1: { label: "Scheduler"; class: infra }
  9,2: { label: "Controller\nManager"; class: infra }
  9,3: { label: "etcd"; class: infra }
  9,5: { label: "Kubelet"; class: infra }
  9,6: { label: "K3d"; class: infra }
  9,8: { label: "Containerd"; class: infra }
  9,9: { label: "Storage"; class: infra }
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
