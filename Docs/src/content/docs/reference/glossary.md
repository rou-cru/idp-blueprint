---
title: Glossary
sidebar:
  label: Glossary
  order: 9
---

Key terms and abbreviations used across the documentation.

:::note
This glossary focuses on terms *as they are used in this blueprint*. Standard definitions (CNCF, etc.) apply, but we highlight our specific implementation choices.
:::

## Core Platform Concepts

### IDP (Internal Developer Platform)

A self-service layer that provides developers with tools, workflows, and infrastructure for building, deploying, and operating applications without requiring deep infrastructure knowledge.

### GitOps

Operational model where Git is the single source of truth for declarative infrastructure and applications. Changes are deployed automatically through continuous reconciliation loops.

### Infrastructure as Code (IaC)

Practice of managing and provisioning infrastructure through machine-readable definition files, rather than manual processes or interactive configuration tools.

### Declarative Configuration

Approach where you describe the desired end state of a system, and automation determines how to achieve that state, as opposed to imperative scripts that execute specific steps.

## ArgoCD & GitOps Components

### ApplicationSet

ArgoCD controller that generates multiple Applications dynamically from templates and generators, enabling patterns like multi-cluster deployment and directory-based app discovery.

### App-of-AppSets Pattern

Architecture pattern where a root ArgoCD Application manages multiple ApplicationSets, which in turn generate Applications for each component. Used in this blueprint for modular stack management.

### Sync Waves

ArgoCD annotation (`argocd.argoproj.io/sync-wave`) that controls the order in which resources are applied, ranging from -3 (foundational infrastructure) to +3 (user-facing services).

### AppProject

ArgoCD resource that defines security boundaries for Applications, specifying allowed source repositories and destination clusters/namespaces.

### Self-Heal

ArgoCD feature that automatically reverts manual changes to resources, ensuring cluster state matches Git. Enabled by default in this blueprint.

## Kubernetes Resources & CRDs

### ServiceMonitor

Custom Resource Definition (CRD) from Prometheus Operator that declares how to scrape metrics from a Kubernetes service. Used throughout the platform for automatic metrics discovery.

### ClusterPolicy

Kyverno Custom Resource that defines cluster-wide validation, mutation, or generation rules. Policies in this blueprint run primarily in audit mode.

### ExternalSecret

Custom Resource from External Secrets Operator that syncs secrets from external sources (like Vault) into Kubernetes Secrets.

### PushSecret

Custom Resource from External Secrets Operator that pushes secrets from Vault to external cloud secret managers (AWS Secrets Manager, GCP Secret Manager, etc.).

### Gateway API

Kubernetes-native API for service exposure and traffic routing, successor to Ingress. Provides HTTPRoute, TLSRoute, and other route types.

### HTTPRoute

Gateway API resource that defines HTTP routing rules, including hostnames, path matching, and backend service references.

### PriorityClass

Kubernetes resource that assigns priority values to pods, determining scheduling and eviction order during resource pressure.

## Secrets & Security

### Vault

HashiCorp's secrets management tool. Used as the single source of truth for all secrets in this platform.

### ESO (External Secrets Operator)

Kubernetes operator that synchronizes secrets from external secret stores (Vault, AWS Secrets Manager, etc.) into Kubernetes Secrets.

### ClusterSecretStore

External Secrets Operator resource that defines how to authenticate to a secret backend (like Vault) at the cluster level, usable by ExternalSecrets in any namespace.

### KV v2

Vault's versioned key-value secrets engine. Stores secrets with version history and metadata.

### mTLS (Mutual TLS)

Authentication method where both client and server verify each other's certificates. Planned for pod-to-pod communication via Cilium.

## Observability

### Prometheus

Pull-based metrics collection system. Scrapes metrics from targets based on ServiceMonitor configurations.

### Loki

Log aggregation system designed to be cost-effective and efficient. Stores logs with labels (similar to Prometheus).

### Grafana

Visualization and dashboarding platform. Queries Prometheus for metrics and Loki for logs.

### Fluent-bit

Lightweight log forwarder deployed as a DaemonSet. Collects container logs and forwards to Loki.

### ServiceMonitor Label

Label applied to ServiceMonitor resources to indicate which Prometheus instance should discover them. This blueprint uses `prometheus: kube-prometheus`.

### SLO (Service Level Objective)

Target value or range for a service level metric. Managed as code via Pyrra in this platform.

## Policy & Governance

### Kyverno

Kubernetes-native policy engine that validates, mutates, and generates resources. Policies are defined as CRDs.

### Policy Reporter

Tool that surfaces Kyverno PolicyReports in a UI and exports metrics to Prometheus.

### Audit Mode

Kyverno validation mode where policy violations are reported but don't block resource creation. Used for most policies in this blueprint.

### Enforce Mode

Kyverno validation mode where policy violations block resource creation. Used for critical policies like namespace labeling.

## Networking

### Cilium

eBPF-based CNI (Container Network Interface) providing networking, security, and observability for Kubernetes.

### Hubble

Cilium's observability component providing network flow visibility without application instrumentation.

### NetworkPolicy

Kubernetes resource defining network segmentation rules (L3/L4 firewall). Cilium extends this with L7 policies.

### cert-manager

Kubernetes operator that automates certificate issuance and renewal from various sources (self-signed CA, Let's Encrypt, etc.).

## Development & CI/CD

### Argo Workflows

Kubernetes-native workflow engine for orchestrating parallel jobs and DAGs (Directed Acyclic Graphs).

### SonarQube

Code quality and security scanning platform. Integrated into CI/CD pipelines for static analysis.

### Trivy

Container image and filesystem vulnerability scanner. Runs as an operator to continuously scan workloads.

### Backstage

Developer portal that provides a unified interface for services, documentation, and platform tools.

## Platform-Specific Tools

### nip.io

Wildcard DNS service that maps any IP address to a hostname (e.g., `192-168-1-20.nip.io` resolves to `192.168.1.20`). Used for local development without DNS configuration.

### k9s

Terminal-based Kubernetes UI for managing and monitoring cluster resources in real-time. Ships in the Dev Container.
[Installation →](https://k9scli.io/)

### k3d

Tool for running k3s (lightweight Kubernetes) in Docker. Used for local development clusters.
[Documentation →](https://k3d.io/)

### Taskfile

Task runner (similar to Make) using `Taskfile.yaml`. All platform operations use `task` commands.
[Documentation →](https://taskfile.dev/)

## Repository Structure

### IT/ Directory

"Infrastructure & Tooling" directory containing bootstrap components installed before GitOps takes over.
[Learn more →](../architecture/infrastructure.md)

### K8s/ Directory

Directory containing all GitOps-managed application stacks, organized by concern (observability, cicd, security, etc.).
[Learn more →](../architecture/applications.md)

### Policies/ Directory

Directory containing Kyverno policies and Policy Reporter configuration, deployed during bootstrap.
[Learn more →](../architecture/policies.md)

## See Also

- [Design Philosophy](../concepts/design-philosophy.md) - Core principles guiding the platform
- [GitOps Model](../concepts/gitops-model.md) - How Git-driven reconciliation works
- [Security & Policy Model](../concepts/security-policy-model.md) - Security architecture and trade-offs
- [Architecture Overview](../architecture/overview.md) - High-level system design
