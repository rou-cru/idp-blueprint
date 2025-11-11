# IDP Blueprint Documentation

**IDP Blueprint** is an Internal Developer Platform reference architecture designed for modern cloud-native environments. This comprehensive platform engineering solution provides a complete stack including GitOps, observability, security, and policy enforcement, deployable for development, testing, and production environments. Also follows FinOps tagging practices to be prepared in case you add FinOps to the development cycle.

---

## Quick Navigation

<div class="grid cards" markdown>

-   **Getting Started**

    ---

    Comprehensive deployment documentation for platform engineers and architects.

    [:octicons-arrow-right-24: Quick Start Guide](getting-started/quickstart.md)

-   **Architecture**

    ---

    Detailed platform design, architectural patterns, and component integration strategies.

    [:octicons-arrow-right-24: Architecture Overview](architecture/overview.md)

-   **Components**

    ---

    Technical specifications for ArgoCD, Kyverno, Prometheus, Vault, and integrated services.

    [:octicons-arrow-right-24: Browse Components](components/infrastructure/index.md)

-   **Guides**

    ---

    Implementation guides, best practices, and advanced configuration procedures.

    [:octicons-arrow-right-24: View Guides](guides/overview.md)

</div>

---

## Documentation Structure

### [Getting Started](getting-started/overview.md)
Deployment and configuration documentation:

- **[Prerequisites](getting-started/prerequisites.md)** - Infrastructure requirements and system dependencies
- **[Quick Start](getting-started/quickstart.md)** - Rapid deployment procedures
- **[Deployment Guide](getting-started/deployment.md)** - Comprehensive deployment process

### [Architecture](architecture/overview.md)
Platform architecture and design patterns:

- **[Visual Architecture](architecture/visual.md)** - System diagrams and component relationships
- **[Infrastructure Layer](architecture/infrastructure.md)** - Core platform infrastructure
- **[Application Layer](architecture/applications.md)** - GitOps-managed application workloads
- **[Secrets Management](architecture/secrets.md)** - HashiCorp Vault and External Secrets integration

### [Components](components/infrastructure/index.md)
Component-level technical documentation:

- **[Infrastructure](components/infrastructure/index.md)** - Cilium CNI, Cert-Manager, Vault, ArgoCD
- **[Policy Enforcement](components/policy/index.md)** - Kyverno policy engine and reporting
- **[Observability](components/observability/index.md)** - Prometheus, Grafana, Loki stack
- **[CI/CD](components/cicd/index.md)** - Argo Workflows and SonarQube integration
- **[Security](components/security/index.md)** - Trivy vulnerability scanning

### [Guides](guides/overview.md)
Implementation guides and best practices:

- **[Contributing](guides/contributing.md)** - Contribution guidelines and development workflow
- **[Policy Tagging](guides/policy-tagging.md)** - Kyverno policy management

### [Reference](reference/overview.md)
Technical specifications and reference material:

- **[Resource Requirements](reference/resource-requirements.md)** - Compute, memory, and storage specifications
- **[Troubleshooting](reference/troubleshooting.md)** - Diagnostic procedures and solutions
- **[Label Standards](reference/labels-standard.md)** - Kubernetes resource labeling standards

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
