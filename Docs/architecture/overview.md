# Architecture Overview

This document provides a comprehensive view of the IDP Blueprint's architecture. It's designed to give you the mental model you need to understand how the pieces fit together, why they're organized this way, and what makes this platform work in resource-constrained environments.

## What You're Looking At

This is an Internal Developer Platform designed to run in resource-constrained edge environments. The entire stack deploys with a single command. Everything runs on Kubernetes, which means the underlying infrastructure (bare metal, on-premise, or public cloud) becomes a deployment detail rather than an architectural constraint.

The approach is straightforward: use CNCF projects and well-established patterns to build a platform without relying on commercial licenses or cloud-specific services. Whether that strategy works for your use case is something you'll determine as you explore the architecture and implementation.

## Design Context: Edge Computing Constraints

Before diving into the architecture, it's important to understand the environment this platform is designed for. Unlike traditional cloud or datacenter deployments where resources are virtually unlimited, this IDP operates under edge computing constraints:

| Aspect | Cloud/Datacenter | Edge (This IDP) |
|--------|-----------------|----------------|
| **Resources** | Elastic, virtually unlimited | Fixed and limited (e.g., 3 nodes) |
| **Failure Domain** | Small impact (1 VM in thousands) | Large impact (33% capacity loss per node) |
| **Connectivity** | High-speed, stable, redundant | Can be unreliable or latent |
| **Recovery Model** | Redundancy and replacement | Resilience and graceful degradation |
| **Primary Goal** | Maintain performance through scaling | Maintain core functionality in degraded state |

These constraints inform every architectural decision. Performance matters, but so does resource efficiency. High availability is achieved through intelligent scheduling and tiered criticality, not through throwing more replicas at the problem.

## System Context

```d2
../C4-L2.d2
```

The diagram above shows the C4 Level 2 Container view of the platform. It illustrates:

- **Actors**: Platform Engineers who build and maintain the IDP, and Application Developers who use it
- **External Systems**: Git as the single source of truth, and a Container Registry for image storage
- **Internal Containers**: The components that make up the IDP itself

The architecture follows a GitOps-first approach. Everything flows from declarative manifests stored in Git. ArgoCD continuously reconciles the cluster state with what's defined in the repository. This creates an audit trail, enables disaster recovery, and makes the entire platform reproducible.

## Abstraction Layers

The platform is organized into five distinct layers, each building on the one below:

```d2
diagrams/abstraction-layers.d2
```

### Layer 0: Infrastructure Core

**Cilium** and **Kubernetes** form the invisible foundation. Cilium is the CNI (Container Network Interface), chosen for its eBPF-based architecture that delivers high performance with low resource overhead. Hubble, Cilium's observability component, provides network visibility without requiring instrumentation. Kubernetes provides the orchestration substrate for everything above.

### Layer 1: Platform Services

This layer contains cross-cutting services that every component in the platform depends on:

- **Vault**: Centralized secrets management, portable across environments
- **Cert-Manager**: Automated TLS certificate lifecycle with zero operational toil
- **Gateway API**: Modern L7 routing, the successor to Ingress
- **Prometheus**: Metrics collection using a pull model optimized for resource efficiency
- **Loki**: Log aggregation that scales from single-pod edge deployments to massive production clusters
- **Fluent-bit**: Lightweight log forwarding agent, chosen for extreme performance

These services are transversal. They touch nearly every part of the platform.

### Layer 2: Automation & Governance Engines

The "brains" of the platform. These components translate declarative intent (code) into cluster state (reality):

- **ArgoCD**: The GitOps engine, continuously reconciling desired state with observed state
- **Kyverno**: Policy engine that validates, mutates, and generates Kubernetes resources
- **External Secrets**: Synchronizes secrets from Vault into Kubernetes Secrets
- **Argo Workflows**: DAG-based workflow engine for CI/CD pipelines

These engines operate autonomously. Once configured, they handle reconciliation loops, policy enforcement, and secret synchronization without manual intervention.

### Layer 3: Developer-Facing Applications

User interfaces and domain-specific tools:

- **Grafana**: Unified visualization for metrics, logs, and traces
- **SonarQube**: Static code analysis for quality gates
- **Policy Reporter**: Dashboard for Kyverno policy compliance
- **ArgoCD UI**: Visual representation of application deployment status

These applications consume the APIs and data from layers below, presenting them in human-friendly formats.

### Layer 4: Unified Developer Portal

**Backstage** (planned) sits at the top, providing a single pane of glass. It unifies the fragmented experience of interacting with multiple tools into a cohesive developer portal. This is the layer that reduces cognitive load and makes the platform truly self-service.

## Core Architectural Patterns

The platform is built around four fundamental patterns. Each represents a cluster of tightly integrated components that solve a specific cross-cutting concern.

### 1. Secrets Management

**Flow**: `Vault` (stores) → `External Secrets` (syncs) → `Kubernetes Secret` (abstracts) → `Applications` (consume)

Vault is the source of truth for all secrets. External Secrets Operator synchronizes them into Kubernetes Secrets as needed. Applications consume standard Kubernetes Secrets, decoupling them from Vault's API. This pattern prevents secrets from being committed to Git, supports secret rotation, and maintains portability (you're not locked into a cloud provider's secret manager).

The `creationPolicy: Merge` setting is critical here. It allows both Helm charts and External Secrets to manage the same Secret resource without conflict.

See [Secrets Management](../concepts/secrets-management.md) for detailed flows.

### 2. Public Key Infrastructure (PKI)

**Flow**: `Self-Signed Issuer` → `CA Root Certificate` → `CA Issuer` → `Application Certificates`

Cert-Manager automates the entire certificate lifecycle. A self-signed ClusterIssuer bootstraps a Certificate Authority (CA). That CA backs a CA Issuer, which then issues certificates for applications (like the wildcard certificate used by the Gateway).

Certificates auto-renew before expiration. The operational toil is zero. This pattern becomes even more valuable when mTLS is introduced in the future.

See [Visual Architecture](visual.md) for certificate flow diagrams.

### 3. Observability Pipeline

**Metrics (Pull)**: `Prometheus` ← `ServiceMonitors` ← `Applications`

**Logs (Push)**: `Fluent-bit` → `Loki`

**Visualization**: `Grafana` → `Prometheus` + `Loki`

Prometheus discovers metrics exporters via ServiceMonitor CRDs and scrapes them on a schedule (pull model). Fluent-bit runs as a DaemonSet on every node, capturing container logs and forwarding them to Loki (push model). Grafana queries both data sources, providing a unified view.

This hybrid approach optimizes for resource efficiency. The pull model for metrics allows precise control over cardinality and scrape intervals. The push model for logs ensures they're captured even if a pod crashes immediately.

See [Observability Model](../concepts/observability-model.md) for detailed architecture.

### 4. Policy Enforcement

**Flow**: `ClusterPolicy` (config) → `Kyverno` (engine) → `PolicyReport` (output) → `Policy Reporter` (dashboard)

Policies are defined as Kubernetes CRDs (ClusterPolicy resources). Kyverno watches for resource creation and modification, evaluating them against policies. It can validate (accept/reject), mutate (modify), generate (create related resources), and verify (check image signatures).

PolicyReports capture compliance status. Policy Reporter aggregates and visualizes these reports.

Most policies currently run in `audit` mode (violations are reported but not blocked). This is intentional, following the "paved road" philosophy: guide developers toward best practices without creating friction. The `enforce-namespace-labels` policy is an exception, running in `enforce` mode to guarantee that all namespaces have the metadata required for FinOps cost attribution.

See [Security & Policy Model](../concepts/security-policy-model.md) for governance architecture.

## Resilience Strategy

Resource constraints demand a different approach to high availability. Instead of running multiple replicas of everything, the platform uses **tiered criticality** and **intelligent scheduling** to ensure that the most important components survive failures.

### Service Tiers

1. **Core Control Plane**: Kubernetes API, etcd (highest priority)
2. **Critical Infrastructure**: ArgoCD, Prometheus (essential for recovery)
3. **Important Services**: Loki, Argo Events (valuable but secondary)
4. **Application Workloads**: Everything else (lowest priority)

### Scheduling Implementation

- **Master node taint**: Prevents application workloads from consuming control plane resources
- **Tolerations for critical components**: ArgoCD and Prometheus can schedule on the master node as a "lifeboat" if worker nodes fail
- **Pod anti-affinity**: Prefers distributing critical components across nodes, but allows consolidation during failures

### Failure Scenarios

| Scenario | State | Behavior |
|----------|-------|----------|
| All nodes healthy | Green | Optimal distribution, full capacity |
| One worker fails | Yellow | Consolidation on remaining worker, degraded performance but operational |
| Both workers fail | Red | ArgoCD + Prometheus survive on master (minimal "limp-home" mode) |
| All nodes fail | Black | Total outage, requires manual recovery from etcd backup |

This strategy prioritizes survival and operational continuity over peak performance. You always retain visibility (Prometheus) and the ability to repair (ArgoCD), even in degraded states.

See [Disaster Recovery](../operate/disaster-recovery.md) for detailed runbooks.

## Selection Criteria

The components in this stack were chosen based on specific technical requirements:

1. **Performance under resource constraints**: Edge environments have fixed resources, so lightweight tools matter
2. **Declarative patterns**: Everything is GitOps-driven, so tools need to work well with declarative configuration
3. **Active ecosystems**: CNCF projects with strong community support and regular updates
4. **No licensing costs**: Avoids commercial licenses to reduce barriers to adoption
5. **Cloud-agnostic**: Portability across environments (cloud, on-premise, bare metal)

The goal was to identify what's actually needed from a cloud provider (compute, network, storage, hardware-level security) and handle everything else at the platform level using Kubernetes and its ecosystem.

## What's Next?

This overview provides the high-level view. For more detail:

- **[Visual Architecture](visual.md)**: Detailed flow diagrams for every major subsystem
- **[Infrastructure Layer](infrastructure.md)**: How the bootstrap process works
- **[Application Layer](applications.md)**: GitOps structure and ApplicationSet patterns
- **[Bootstrap Process](bootstrap.md)**: The sequence of steps that bring the platform online
- **[Components](../components/)**: Per-component deep dives, including why each was chosen

Explore the sections above to understand how the pieces connect.
