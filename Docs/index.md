# IDP Blueprint — A readable reference IDP

IDP Blueprint is an Internal Developer Platform you can run locally, reason about, and adapt to your environment. It is designed to run well from a small 3‑node demo cluster up to larger, production‑like Kubernetes environments, and uses a GitOps‑first architecture with widely adopted open source components.

Use this documentation as a map to the platform: understand the architecture, deploy the reference cluster, then evolve components and operations to fit your own environment.

## One picture: IDP Blueprint architecture

```d2
grid-rows: 4
style.fill: black

classes: {
  layer0: {
    width: 260
    style: {
      fill: navy
      stroke: deepskyblue
      stroke-width: 3
      font-color: white
      text-transform: uppercase
    }
  }
  layer1: {
    width: 220
    style: {
      fill: midnightblue
      stroke: mediumseagreen
      stroke-width: 3
      font-color: white
      text-transform: uppercase
    }
  }
  layer2: {
    width: 220
    style: {
      fill: black
      stroke: mediumorchid
      stroke-width: 3
      font-color: white
      text-transform: uppercase
    }
  }
  layer3: {
    width: 220
    style: {
      fill: black
      stroke: orange
      stroke-width: 3
      font-color: white
      text-transform: uppercase
    }
  }
}

# Row 1: developer-facing surfaces

grafana: {
  class: layer3
  label: "Grafana"
}

workflows: {
  class: layer3
  label: "Argo Workflows"
}

sonarqube: {
  class: layer3
  label: "SonarQube"
}

trivy: {
  class: layer3
  label: "Trivy"
}

argocd: {
  class: layer3
  label: "ArgoCD"
}

# Row 2: automation & governance

appsets: {
  class: layer2
  label: "ApplicationSets"
}

kyverno: {
  class: layer2
  label: "Kyverno"
}

policy_reporter: {
  class: layer2
  label: "Policy Reporter"
}

vault: {
  class: layer2
  label: "Vault"
}

# Row 3: platform services

eso: {
  class: layer1
  label: "External Secrets"
}

cert_manager: {
  class: layer1
  label: "cert-manager"
}

prom: {
  class: layer1
  label: "Prometheus"
}

loki: {
  class: layer1
  label: "Loki"
}

fluent: {
  class: layer1
  label: "Fluent-bit"
}

# Row 4: infrastructure core

kubernetes: {
  class: layer0
  label: "Kubernetes"
}

cilium: {
  class: layer0
  label: "Cilium CNI"
}

gateway: {
  class: layer0
  label: "Gateway API"
}
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

**IDP Blueprint** is open source software licensed under the [MIT License](https://github.com/rou-cru/idp-blueprint/blob/main/LICENSE).
