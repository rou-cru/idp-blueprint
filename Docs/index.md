# IDP Blueprint Documentation

**IDP Blueprint** is an Internal Developer Platform reference architecture designed for modern cloud-native environments. This comprehensive platform engineering solution provides a complete stack including GitOps, observability, security, and policy enforcement, deployable for development, testing, and production environments. Also follows FinOps tagging practices to be prepared in case you add FinOps to the development cycle.

---

## IDP Blueprint (Conceptual)

```d2
direction: right

classes: {
  aux:  { style: { fill: "#F7F9FC" } }
  main: { style: { fill: "#FFFFFF" } }
  band: { style: { fill: "#EEF3F7" } }
  pill: { style: { fill: "#E9F0FF" } }
}

Canvas: {
  grid: {
    columns: 3
    gap: 24
  }

  LeftCol: {
    class: aux
    label: "IDP Platform"
    grid: { row: 1 col: 1 }
    grid: {
      columns: 1
      gap: 8
    }

    A1: { label: "Platform Elements" }
    A2: { label: "System Core" }
  }

  Main: {
    class: main
    label: "IDP"
    grid: { row: 1 col: 2 }
    grid: {
      columns: 6
      gap: 12
    }

    UIs: { class: band label: "UIs" grid: { row: 1 col: 1 colspan: 6 } }

    Quality: { class: pill label: "Quality" grid: { row: 2 col: 1 } }
    Policy:  { class: pill label: "Policy"  grid: { row: 2 col: 2 } }
    Sec:     { class: pill label: "Security" grid: { row: 2 col: 3 } }
    CICD:    { class: pill label: "CI/CD"   grid: { row: 2 col: 4 } }
    Obs:     { class: pill label: "Observability" grid: { row: 2 col: 5 } }

    Secrets: { class: pill label: "Secrets"      grid: { row: 3 col: 2 } }
    Certs:   { class: pill label: "Certificates" grid: { row: 3 col: 3 } }
    Engine:  { class: band label: "GitOps Engine" grid: { row: 3 col: 4 colspan: 3 } }

    Cilium:  { class: band label: "Cilium"      grid: { row: 4 col: 1 colspan: 6 } }
    K8s:     { class: band label: "Kubernetes"  grid: { row: 5 col: 1 colspan: 6 } }
    Infra:   { class: band label: "IT Resources" grid: { row: 6 col: 1 colspan: 6 } }
  }

  RightCol: {
    class: aux
    grid: { row: 1 col: 3 }
    grid: {
      columns: 1
      gap: 8
    }
    P1: { label: "Dev Portal" }
  }

  BottomLeft: {
    class: aux
    grid: { row: 2 col: 1 }
    grid: {
      columns: 1
      gap: 8
    }
    C: { label: "Costs" }
    O: { label: "Opex" }
  }

  BottomRight: {
    class: aux
    grid: { row: 2 col: 3 }
    grid: {
      columns: 1
      gap: 8
    }
    HA: { label: "Hardware Abstr." }
    HW: { label: "Hardware" }
  }
}
```

## IDP Blueprint (Implementation)

```d2
direction: right

classes: {
  aux:  { style: { fill: "#F7F9FC" } }
  main: { style: { fill: "#FFFFFF" } }
  band: { style: { fill: "#EEF3F7" } }
  pill: { style: { fill: "#E9F0FF" } }
}

Canvas: {
  grid: {
    columns: 3
    gap: 24
  }

  LeftCol: {
    class: aux
    label: "IDP Platform"
    grid: { row: 1 col: 1 }
    grid: {
      columns: 1
      gap: 8
    }
    A1: { label: "Platform Elements" }
    A2: { label: "System Core" }
  }

  Main: {
    class: main
    label: "IDP"
    grid: { row: 1 col: 2 }
    grid: {
      columns: 6
      gap: 12
    }

    UIs: { class: band label: "UIs" grid: { row: 1 col: 1 colspan: 6 } }

    GitHub:     { class: pill label: "GitHub"     grid: { row: 2 col: 1 } }
    Backstage:  { class: pill label: "Backstage"  grid: { row: 2 col: 2 } }
    Kyverno:    { class: pill label: "Kyverno"    grid: { row: 2 col: 3 } }
    Workflows:  { class: pill label: "Workflows"  grid: { row: 2 col: 4 } }
    Grafana:    { class: pill label: "Grafana"    grid: { row: 2 col: 5 } }

    Vault:      { class: pill label: "Vault"         grid: { row: 3 col: 2 } }
    CertMgr:    { class: pill label: "Cert-Manager"  grid: { row: 3 col: 3 } }
    ArgoCD:     { class: band label: "ArgoCD / AppSets" grid: { row: 3 col: 4 colspan: 3 } }

    Cilium:     { class: band label: "Cilium"     grid: { row: 4 col: 1 colspan: 6 } }
    K8s:        { class: band label: "Kubernetes" grid: { row: 5 col: 1 colspan: 6 } }
    Infra:      { class: band label: "IT Resources" grid: { row: 6 col: 1 colspan: 6 } }
  }

  RightCol: {
    class: aux
    grid: { row: 1 col: 3 }
    grid: {
      columns: 1
      gap: 8
    }
    P1: { label: "Dev Portal" }
  }

  BottomLeft: {
    class: aux
    grid: { row: 2 col: 1 }
    grid: {
      columns: 1
      gap: 8
    }
    C: { label: "Costs" }
    O: { label: "Opex" }
  }

  BottomRight: {
    class: aux
    grid: { row: 2 col: 3 }
    grid: {
      columns: 1
      gap: 8
    }
    HA: { label: "Hardware Abstr." }
    HW: { label: "Hardware" }
  }
}
```

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
