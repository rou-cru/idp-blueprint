# Concepts Overview

Start here to understand the architectural principles behind the IDP Blueprint.
This section distills the *why* behind each layer before you dive into
implementation details.

## Key Topics

- **Platform Overview** – High-level goals, personas, and scope of the blueprint.
- **Visual Architecture** – End-to-end diagrams showing control planes, network
  paths, and GitOps flows.
- **Infrastructure Layer** – Bootstrap services (namespaces, networking, Vault,
  gateways) that every environment needs.
- **Application Layer** – How GitOps-driven workloads, namespaces, and
  ApplicationSets are structured.
- **Observability Stack** – Metrics, logs, and alerting data flow references.
- **Secrets & Policy** – Vault + External Secrets orchestration and Kyverno
  policy layers.

## When To Read This

- Evaluating the blueprint for your organization.
- Onboarding new platform engineers or architects.
- Planning extensions or customizations before touching manifests.

## Next Steps

1. Review the [Platform Overview](../architecture/overview.md).
2. Walk through the [Visual Architecture](../architecture/visual.md) to connect
   components.
3. Jump into [How-to Guides](../how-to/index.md) when you are ready to deploy.
