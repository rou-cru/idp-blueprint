# Platform Operations Overview

Operate every subsystem of the IDP Blueprint—from bootstrap infrastructure to
observability and CI/CD—using the component guides in this section.

## Layers

- **Infrastructure** – Cilium, Cert-Manager, Vault, External Secrets, ArgoCD,
  and supporting namespaces.
- **Policy & Security** – Kyverno policies, Policy Reporter, Trivy scanning, and
  governance guidance.
- **Observability** – Prometheus, Grafana, Loki, Fluent Bit, dashboards, and
  alerting hooks.
- **CI/CD** – Argo Workflows, SonarQube, and the supporting automation that
  project teams touch daily.

## How To Use

Each component page includes:

1. **Summary & diagrams** – Why the component exists and how it fits into the
   flow.
2. **Values & configuration** – Helm/Kustomize knobs maintained by GitOps.
3. **Operational guidance** – Scaling tips, dashboards, and health checks.

## Quick Links

- [Infrastructure Stack](../components/infrastructure/index.md)
- [Policy & Security](../components/policy/index.md)
- [Observability](../components/observability/index.md)
- [CI/CD](../components/cicd/index.md)
