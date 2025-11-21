# IDP Blueprint — Production-Ready Internal Developer Platform Reference

**IDP Blueprint** is a comprehensive, production-ready **Internal Developer Platform (IDP)** that serves as a reference architecture for **Platform Engineering** teams. Built with industry-standard open-source tools and **GitOps** principles, this platform delivers a complete developer experience from local development to enterprise production environments.

This **platform engineering blueprint** demonstrates how to build, operate, and scale an Internal Developer Platform using **Kubernetes**, **ArgoCD**, **Kyverno**, and a complete **observability stack**. Whether you're building your first IDP or modernizing existing infrastructure, this reference implementation provides battle-tested patterns and architectural decisions for **cloud-native platform engineering**.

Use this documentation as your comprehensive guide to **Platform Engineering**: understand the architecture, deploy the reference cluster, explore GitOps workflows, and adapt components to fit your environment. Perfect for **Platform Engineers**, **SRE teams**, and **DevOps practitioners** implementing **Platform as a Product** strategies.

## One picture: IDP Blueprint architecture

```d2
direction: right

classes: {
  actors: { style.fill: "#0f172a"; style.font-color: white; style.stroke: "#38bdf8" }
  system: { style.fill: "#111827"; style.font-color: white; style.stroke: "#22d3ee" }
  infra:  { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  gov:    { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  svc:    { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  ux:     { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
}

External: {
  class: actors
  Devs: "Developers"
  Platform: "Platform Engineers"
  Security: "Security/Compliance"
}

IDP: {
  class: system
  label: "IDP Blueprint cluster"

  Infra: {
    class: infra
    label: "Infrastructure Core"
    K8s: "Kubernetes API\n+ etcd"
    Cilium
    Gateway: "Gateway API"
    Cert: "cert-manager"
  }

  Governance: {
    class: gov
    label: "Automation & Governance"
    Argo: "ArgoCD + ApplicationSets"
    Kyverno
    Vault
    ESO: "External Secrets"
  }

  Services: {
    class: svc
    label: "Platform Services"
    Prom: "Prometheus"
    Loki
    Fluent: "Fluent-bit"
  }

  UX: {
    class: ux
    label: "Developer-Facing"
    Grafana
    Workflows: "Argo Workflows"
    Sonar: "SonarQube"
    Trivy: "Trivy Operator"
    Backstage
  }
}

External.Devs -> IDP.Governance.Argo: "Git → GitOps"
External.Platform -> IDP.Governance.Argo: "Operate platform"
External.Security -> IDP.Governance.Kyverno: "Guardrails"
External.Devs -> IDP.UX.Backstage: "use catalog/docs"
IDP.Governance.Argo -> IDP.Services.Prom
IDP.Governance.Argo -> IDP.Services.Loki
IDP.Governance.Argo -> IDP.UX.Workflows
IDP.Governance.Argo -> IDP.UX.Sonar
IDP.Governance.Argo -> IDP.UX.Grafana
IDP.Governance.Argo -> IDP.UX.Backstage
IDP.Governance.ESO -> IDP.UX.Workflows: "inject secrets"
IDP.Governance.ESO -> IDP.UX.Sonar
IDP.Governance.ESO -> IDP.UX.Backstage
IDP.Governance.Vault -> IDP.Governance.ESO: "KV read"
IDP.Infra.Gateway -> IDP.UX.Grafana: "HTTPS routes"
IDP.Infra.Gateway -> IDP.UX.Workflows
IDP.Infra.Gateway -> IDP.UX.Sonar
IDP.Infra.Gateway -> IDP.UX.Backstage
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

## Paved-road defaults

- **GitOps**: everything reconciled from Git with ArgoCD and ApplicationSets
  (see [`GitOps, Policy, and Eventing`](concepts/gitops-model.md)).
- **Policies**: labels, limits, and contracts encoded as Kyverno policies.
- **Observability**: metrics, logs, dashboards, and SLOs managed as code.
- **Secrets**: Vault → External Secrets Operator → Kubernetes Secrets (no literals in Git).
- **Networking**: one Gateway, TLS everywhere (demo CA), nip.io‑based hostnames.

---

## How to navigate the docs

<div class="grid cards" markdown>

- **Concepts**

    ---

    Learn the mental model of the platform, its feedback loops, and how GitOps, policy, and events fit together.

    [:octicons-arrow-right-24: Explore Concepts](concepts/index.md)

- **Get Started**

    ---

    Install, verify, and take your first steps with reproducible commands and expected outputs.

    [:octicons-arrow-right-24: Start Building](getting-started/quickstart.md)

- **Components**

    ---

    Dive into infrastructure, policy, observability, and CI/CD components.

    [:octicons-arrow-right-24: Explore Components](components/infrastructure/index.md)

- **Reference**

    ---

    Access canonical labels, FinOps mapping, resource requirements, and troubleshooting matrices.

    [:octicons-arrow-right-24: View Reference](reference/labels-standard.md)

</div>

---

## Who is this for?

<div class="grid cards" markdown>

- **Platform Engineers**

    ---

    Focus on the bootstrap layer, GitOps workflows, and operational guides under *Operate*.

- **Security & Policy Teams**

    ---

    Review Kyverno, Trivy, and governance references within *Components → Policy & Security*.

- **Observability & SRE**

    ---

    Jump to *Components → Observability* for dashboards, alerts, and data flow diagrams.

- **Application Teams**

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
    Platform engineering stack suitable for realistic development, staging, and production-like environments, from small demo clusters up to larger footprints. Typical uses include:

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

## About the Author

**IDP Blueprint** is created and maintained by **[Alberto Roura](https://roura.xyz)**, a Platform Engineering specialist focused on building scalable, production-ready Internal Developer Platforms. Learn more about Platform Engineering practices, cloud-native architectures, and developer experience optimization at **[roura.xyz](https://roura.xyz)**.

For professional inquiries, consulting, or collaboration on Platform Engineering initiatives, visit **[roura.xyz](https://roura.xyz)**.

---

**IDP Blueprint** is open source software licensed under the [MIT License](https://github.com/rou-cru/idp-blueprint/blob/main/LICENSE).

*This documentation is part of the Platform Engineering reference portfolio by [Alberto Roura](https://roura.xyz).*
