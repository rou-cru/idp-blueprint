# Architecture Overview

This section details the architecture of the IDP Blueprint platform.

## Architecture Layers

The platform architecture is organized into distinct layers:

- **[Visual Architecture](visual.md)**: Graphical representation of the platform architecture
- **[Infrastructure Layer](infrastructure.md)**: Static bootstrap components and core infrastructure
- **[Application Layer](applications.md)**: GitOps-managed application stacks
- **[Secrets Management](../concepts/secrets-management.md)**: Architecture for secrets management and synchronization

## Components

The platform consists of several key component categories:

- **Infrastructure**: Core foundational services including Cilium CNI, Cert Manager, Vault, External Secrets, and ArgoCD
- **Policy**: Policy enforcement with Kyverno and Policy Reporter
- **Observability**: Monitoring and logging with Prometheus, Grafana, Loki, and Fluent-bit
- **CI/CD**: Workflow orchestration with Argo Workflows and code quality analysis with SonarQube
- **Security**: Vulnerability scanning and compliance checking with Trivy

## Design Principles

The architecture follows key design principles:
- GitOps-first approach
- Policy-as-code
- Resource optimization
- Security-first
- Observability-driven
