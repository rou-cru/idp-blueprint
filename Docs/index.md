# IDP Blueprint — The platform you can read, reason about, and change

IDP Blueprint is an Internal Developer Platform you can understand end‑to‑end. It favors declarative intent, strong guardrails, and visual explanations so you can adopt it, extend it, and trust it.

## One picture: Desired → Observed → Actionable

```d2
direction: right

Desired: {
  label: "Desired State (Git)"
  Code: "Manifests, Values, Policies, SLOs"
}

Observed: {
  label: "Observed State"
  Metrics: "Prometheus"
  Logs: "Loki"
  SLOs: "Pyrra"
}

Actionable: {
  label: "Actionable State"
  GitOps: "ArgoCD"
  Policy: "Kyverno"
  Events: "Argo Events (planned)"
  Portal: "Backstage (planned)"
}

Desired.Code -> Actionable.GitOps: reconcile
Desired.Code -> Actionable.Policy: govern
Observed.Metrics -> Actionable.Events: emit → trigger
Observed.SLOs -> Actionable.Events: burn → playbook
Actionable.GitOps -> Observed.Metrics: deploy → measure
```

![ArgoCD Applications](assets/images/after-deploy/argocd-apps-healthy.jpg){ loading=lazy }

## The paved road (defaults that matter)

- GitOps: everything reconciled from Git, in order, with waves
- Policies: conventions turned into guarantees (labels, limits, contracts)
- Observability: metrics, logs, dashboards, SLOs as code
- Secrets: Vault → ESO → Kubernetes Secrets (never literals)
- Networking: one Gateway, TLS everywhere (demo CA), nip.io URLs

![Grafana](assets/images/after-deploy/grafana-home.jpg){ loading=lazy }

---

## Choose your journey

<div class="grid cards" markdown>

- **Concepts**

    ---

    Learn the platform architecture, design tenets, and control backbone. Written to be read like a technical Medium post.

    [:octicons-arrow-right-24: Explore Concepts](architecture/overview.md)

-   **Get Started**

    ---

    Install, verify, and take your first steps. Expect a smooth paved road.

    [:octicons-arrow-right-24: Start Building](getting-started/quickstart.md)

-   **Components**

    ---

    Dive into infrastructure, policy, observability, and CI/CD components.

    [:octicons-arrow-right-24: Explore Components](components/infrastructure/index.md)

-   **Reference**

    ---

    Access canonical labels, FinOps mapping, resource requirements, and troubleshooting matrices.

    [:octicons-arrow-right-24: View Reference](reference/labels-standard.md)

</div>

---

## Who is this for?

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

## Documentation structure

### [Getting Started](getting-started/overview.md)
Deployment and configuration documentation:

- **[Prerequisites](getting-started/prerequisites.md)** - Infrastructure requirements and system dependencies
- **[Quick Start](getting-started/quickstart.md)** - Rapid deployment procedures
- **[Deployment Guide](getting-started/deployment.md)** - Comprehensive deployment process

- ### Concepts
  - [Platform Overview](architecture/overview.md)
  - [Visual Architecture](architecture/visual.md)
  - [Platform Layers](architecture/infrastructure.md)

  
  

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

## Platform technology stack

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

## Platform capabilities

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
