# IDP Blueprint — A readable reference IDP

IDP Blueprint is an Internal Developer Platform you can run locally, reason about, and adapt to your environment. It targets small, resource‑constrained Kubernetes clusters (for example 1–3 nodes) and uses a GitOps‑first architecture with widely adopted open source components.

The goal of these docs is to explain the platform as a system: what it is, how it is wired, and how to change it safely.

## One picture: IDP Blueprint architecture

```d2
direction: down
layout: elk

platform_engineer: |md
  ## Platform Engineer
  [Person]
| { shape: c4-person }

developer: |md
  ## Application Developer
  [Person]
| { shape: c4-person }

git_provider: |md
  ## Git Provider
  [Software System]
| { shape: rectangle }

container_registry: |md
  ## Container Registry
  [Software System]
| { shape: rectangle }

idp: |md
  ## Internal Developer Platform (IDP)
  [Software System]
| {
  shape: rectangle
  style.stroke-width: 3

  argo_cd: |md
    ## ArgoCD
    [Container: GitOps Engine]
  | { shape: rectangle }

  sonarqube: |md
    ## SonarQube
    [Container: Code Quality]
  | { shape: rectangle }

  observability: {
    shape: rectangle
    style.stroke-width: 2
    label: "Observability Stack"

    prometheus: |md
      ## Prometheus
      [Container: Metrics]
    | { shape: rectangle }

    loki: |md
      ## Loki
      [Container: Logs]
    | { shape: rectangle }

    grafana: |md
      ## Grafana
      [Container: Visualization]
    | { shape: rectangle }

    fluent_bit: |md
      ## Fluent-bit
      [Container: Log Agent]
    | { shape: rectangle }
  }

  security: {
    shape: rectangle
    style.stroke-width: 2
    label: "Security Stack"

    kyverno: |md
      ## Kyverno
      [Container: Policy Engine]
    | { shape: rectangle }

    vault: |md
      ## Vault
      [Container: Secrets Backend]
    | { shape: rectangle }

    external_secrets: |md
      ## External Secrets Operator
      [Container: Secret Sync]
    | { shape: rectangle }
  }
}

developer -> git_provider
platform_engineer -> git_provider

git_provider -> idp.argo_cd

idp.argo_cd -> idp.security.kyverno
idp.argo_cd -> idp.security.external_secrets

idp.security.external_secrets -> idp.security.vault

idp.observability.fluent_bit -> idp.observability.loki

idp.observability.prometheus -> idp.observability.grafana
idp.observability.loki -> idp.observability.grafana
developer -> idp.observability.grafana
```

At a glance:

- **Context**: a single Kubernetes cluster, Git as the source of truth, a container registry, and engineers using the platform.
- **Layers**:
  - Infrastructure core: Kubernetes, Cilium, Gateway API.
  - Platform services: Vault, cert‑manager, External Secrets, Prometheus, Loki, Fluent‑bit.
  - Automation & governance: ArgoCD (GitOps controller), Kyverno (policies),
    ApplicationSets (generate many Applications from folders).
  - Developer‑facing stacks: Observability, CI/CD, Security.

See [Architecture Overview](architecture/overview.md) for the full walkthrough.

## The paved road (opinionated defaults)

- **GitOps**: everything reconciled from Git with ArgoCD and ApplicationSets
  (see [`GitOps, Policy, and Eventing`](concepts/gitops-model.md)).
- **Policies**: labels, limits, and contracts encoded as Kyverno policies.
- **Observability**: metrics, logs, dashboards, and SLOs managed as code.
- **Secrets**: Vault → External Secrets Operator → Kubernetes Secrets (no literals in Git).
- **Networking**: one Gateway, TLS everywhere (demo CA), nip.io‑based hostnames.

---

## Choose your journey

<div class="grid cards" markdown>

- **Concepts**

    ---

    Learn the mental model of the platform, its feedback loops, and how GitOps, policy, and events fit together.

    [:octicons-arrow-right-24: Explore Concepts](concepts/index.md)

-   **Get Started**

    ---

    Install, verify, and take your first steps with reproducible commands and expected outputs.

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

- ### Architecture & Concepts
  - [Architecture Overview](architecture/overview.md)
  - [GitOps Model](concepts/gitops-model.md)
  - [Security & Policy Model](concepts/security-policy-model.md)

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

The platform is built from the following open source components:

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
    Platform engineering stack suitable for realistic development, staging, and smaller production-like environments. Typical uses include:

    - **Enterprise Architecture** - Evaluate cloud-native technologies in realistic deployment scenarios
    - **Infrastructure Prototyping** - Validate infrastructure changes before production rollout
    - **Team Enablement** - Platform engineering training and knowledge transfer
    - **Policy Validation** - Test and validate policies, workflows, and configurations

!!! example "Automated Deployment"
    ```bash
    task deploy
    ```
    Fully automated deployment orchestration including cluster provisioning, component installation, GitOps synchronization, and validation.

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
