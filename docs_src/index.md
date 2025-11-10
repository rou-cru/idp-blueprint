# Welcome to IDP Blueprint Documentation

**IDP Blueprint** is a production-ready Internal Developer Platform that runs entirely on your local machine. Deploy a complete platform engineering stack with GitOps, observability, security scanning, and policy enforcement using a single command.

---

## Quick Navigation

<div class="grid cards" markdown>

-   :rocket: **Getting Started**

    ---

    New to IDP Blueprint? Start here to deploy your platform in minutes.

    [:octicons-arrow-right-24: Quick Start Guide](getting-started/quickstart.md)

-   :material-architecture: **Architecture**

    ---

    Understand the platform's design, components, and how they work together.

    [:octicons-arrow-right-24: Architecture Overview](architecture/overview.md)

-   :material-cube-outline: **Components**

    ---

    Deep dive into each component: ArgoCD, Kyverno, Prometheus, Vault, and more.

    [:octicons-arrow-right-24: Browse Components](components/infrastructure/index.md)

-   :material-book-open-variant: **Guides**

    ---

    Step-by-step guides for common tasks and advanced configurations.

    [:octicons-arrow-right-24: View Guides](guides/overview.md)

</div>

---

## What You'll Find in This Documentation

### :fontawesome-solid-play: [Getting Started](getting-started/overview.md)
Everything you need to deploy and run IDP Blueprint:

- **[Prerequisites](getting-started/prerequisites.md)** - System requirements and dependencies
- **[Quick Start](getting-started/quickstart.md)** - Deploy in 5-10 minutes
- **[Deployment Guide](getting-started/deployment.md)** - Detailed deployment process

### :fontawesome-solid-sitemap: [Architecture](architecture/overview.md)
Understand how the platform works:

- **[Visual Architecture](architecture/visual.md)** - Diagrams and component relationships
- **[Infrastructure Layer](architecture/infrastructure.md)** - Core platform components
- **[Application Layer](architecture/applications.md)** - GitOps-managed workloads
- **[Secrets Management](architecture/secrets.md)** - Vault and External Secrets integration

### :fontawesome-solid-cubes: [Components](components/infrastructure/index.md)
Detailed documentation for each technology:

- **[Infrastructure](components/infrastructure/index.md)** - Cilium, Cert-Manager, Vault, ArgoCD
- **[Policy Enforcement](components/policy/index.md)** - Kyverno and Policy Reporter
- **[Observability](components/observability/index.md)** - Prometheus, Grafana, Loki
- **[CI/CD](components/cicd/index.md)** - Argo Workflows and SonarQube
- **[Security](components/security/index.md)** - Trivy security scanning

### :fontawesome-solid-book: [Guides](guides/overview.md)
Practical how-to guides:

- **[Contributing](guides/contributing.md)** - How to contribute to the project
- **[Policy Tagging](guides/policy-tagging.md)** - Working with Kyverno policies

### :fontawesome-solid-info-circle: [Reference](reference/overview.md)
Technical reference material:

- **[Resource Requirements](reference/resource-requirements.md)** - CPU, memory, and storage specs
- **[Troubleshooting](reference/troubleshooting.md)** - Common issues and solutions
- **[Label Standards](reference/labels-standard.md)** - Kubernetes labeling conventions

---

## Platform at a Glance

IDP Blueprint demonstrates modern **Platform Engineering** best practices:

| Layer | Technologies | Purpose |
|-------|--------------|---------|
| **GitOps** | ArgoCD, ApplicationSets | Declarative infrastructure and application management |
| **Policy** | Kyverno, Policy Reporter | Security and compliance enforcement as code |
| **Observability** | Prometheus, Grafana, Loki, Fluent-bit | Comprehensive metrics, logs, and visualization |
| **Networking** | Cilium CNI | eBPF-based networking and service mesh |
| **Security** | Vault, External Secrets, Trivy | Secret management and vulnerability scanning |
| **CI/CD** | Argo Workflows, SonarQube | Continuous integration and code quality |
| **Certificates** | Cert-Manager | Automated TLS certificate management |

---

## Why IDP Blueprint?

!!! success "Local-First Platform Engineering"
    Run a complete production-grade platform stack on your laptop. Perfect for:

    - **Learning** cloud-native technologies in a realistic environment
    - **Prototyping** infrastructure changes before production
    - **Training** team members on platform engineering concepts
    - **Validating** policies, workflows, and configurations locally

!!! tip "Single Command Deployment"
    ```bash
    task deploy
    ```
    That's all you need. The platform handles the rest - cluster creation, component installation, GitOps sync, and validation.

!!! info "Resource Optimized"
    Designed to run on developer laptops with minimal resources:

    - **Minimum**: 4 CPU cores, 8GB RAM
    - **Recommended**: 6 CPU cores, 12GB RAM
    - **Storage**: ~20GB

---

## Ready to Get Started?

<div class="grid" markdown>

<div markdown>
### :material-lightning-bolt: Deploy Now

Follow the quick start guide to have your platform running in minutes.

[Get Started :octicons-arrow-right-24:](getting-started/quickstart.md){ .md-button .md-button--primary }
</div>

<div markdown>
### :material-github: Source Code

Explore the code, open issues, or contribute to the project.

[View on GitHub :octicons-arrow-right-24:](https://github.com/rou-cru/idp-blueprint){ .md-button }
</div>

</div>

---

## Community & Support

!!! question "Need Help?"
    - **Issues**: [Report bugs or request features](https://github.com/rou-cru/idp-blueprint/issues)
    - **Discussions**: [Ask questions and share ideas](https://github.com/rou-cru/idp-blueprint/discussions)
    - **Contributing**: See our [Contributing Guide](guides/contributing.md)

---

<div align="center" markdown>

**IDP Blueprint** is open source software licensed under the [MIT License](https://github.com/rou-cru/idp-blueprint/blob/main/LICENSE).

Made with :heart: by the Platform Engineering community

[Star on GitHub :octicons-star-24:](https://github.com/rou-cru/idp-blueprint){ .md-button }

</div>
