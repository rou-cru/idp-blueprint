---
title: Overview Architecture
sidebar:
  label: Overview
  order: 1
---

## Context and goals

IDP Blueprint provides a compact, self-hosted platform stack for Kubernetes clusters. The architecture supports edge, on-premises, and constrained environments where horizontal scaling is limited, though the same patterns apply to larger deployments. The platform operates GitOps-first with Git as the source of truth and ArgoCD handling reconciliation. No managed control planes or commercial licenses are required, making it fully cloud-agnostic.

The platform serves three primary use cases. Engineers can evaluate a realistic platform stack on a laptop or lab cluster without cloud dependencies. Teams can prototype internal developer platforms without vendor commitments. Organizations can train platform, SRE, and security engineers on GitOps and policy-driven operations with hands-on infrastructure.

## System context

A single Kubernetes cluster sits between engineers and Git. Git owns all intent, ArgoCD reconciles that intent into the cluster, and traffic flows back out through Gateway API. Platform engineers operate the stack while application teams ship workloads through it. External systems include the Git provider as source of truth, container registries for images, and optional cloud services for external secret stores. The deployment target is one cluster—either local k3d or remote—treated as interchangeable infrastructure.

```d2
direction: right

classes: {
  actor: {
    shape: person
    style: {
      fill: "#1e3a8a"
      stroke: "#60a5fa"
      font-color: white
    }
  }
  system: {
    style: {
      fill: "#111827"
      stroke: "#34d399"
      font-color: white
    }
  }
  ext: {
    style: {
      fill: "#0f172a"
      stroke: "#22d3ee"
      font-color: white
    }
  }
}

Platform Engineer: { class: actor }
Application Developer: { class: actor }

IDP: {
  class: system
  label: "IDP Blueprint\n(Kubernetes Cluster)"
}

Git: {
  class: ext
  label: "Git Provider"
}

Registry: {
  class: ext
  label: "Container Registry"
}

Platform Engineer -> Git: "Configures"
Application Developer -> Git: "Commits code"
Git -> IDP: "Syncs state"
Registry -> IDP: "Provides images"
IDP -> Application Developer: "Serves apps"
Platform Engineer -> IDP: "Observes"
```

## Container view

:::note[C4 Model - Container (Level 2)]
This diagram zooms into the IDP Blueprint system to show the major containers (applications and data stores) and how they interact. Each container is a separately deployable/runnable unit.
:::

The container view groups components into layers and planes:

- **Infrastructure core**
  - Kubernetes API server and etcd (control plane).
  - Cilium CNI and Gateway API for networking and ingress.
- **Platform services**
  - Vault for secrets management.
  - External Secrets Operator (ESO) for syncing Vault → Kubernetes Secrets.
  - cert‑manager for PKI and TLS certificates.
  - Prometheus, Loki, Fluent‑bit, and supporting exporters for metrics and logs.
- **Automation and governance**
  - ArgoCD and ApplicationSets for GitOps reconciliation.
  - Kyverno and Policy Reporter for policy‑as‑code and compliance reporting.
- **Developer‑facing stacks**
  - Observability UIs: Grafana, Pyrra.
  - CI/CD: Argo Workflows, SonarQube.
  - Security: Trivy Operator and related scanners.

All components are either bootstrapped once from `IT/` (infrastructure core) or continuously reconciled from `K8s/` (stacks).

```d2
direction: right

classes: {
  infra: { style: { fill: "#0f172a"; stroke: "#38bdf8"; font-color: white } }
  svc:   { style: { fill: "#0f766e"; stroke: "#34d399"; font-color: white } }
  gov:   { style: { fill: "#111827"; stroke: "#6366f1"; font-color: white } }
  ux:    { style: { fill: "#7c3aed"; stroke: "#a855f7"; font-color: white } }
}

Infra: {
  label: "Infrastructure Layer"
  K8s: { class: infra; label: "K8s API" }
  Gateway: { class: infra; label: "Gateway API" }
  Cilium: { class: infra }
}

Services: {
  label: "Platform Services"
  Vault: { class: svc }
  ESO: { class: svc; label: "External Secrets" }
  Observability: {
    class: svc
    label: "Metrics & Logs"
    tooltip: "Prometheus, Loki, Fluent-bit"
  }
}

Governance: {
  label: "Governance Layer"
  ArgoCD: { class: gov }
  Kyverno: { class: gov }
}

UX: {
  label: "Developer Portals"
  Grafana: { class: ux }
  Backstage: { class: ux }
  Workflows: { class: ux; label: "Argo Workflows" }
}

# Key Flows
Infra.Gateway -> UX: "Routes traffic"
Governance.ArgoCD -> Services: "Deploys"
Governance.ArgoCD -> UX: "Deploys"
Services.ESO -> Services.Vault: "Syncs secrets"
Governance.Kyverno -> Infra.K8s: "Enforces policy"
```

## Platform layers

The same components can be viewed as a set of logical layers:

| Layer                       | Components (examples)                                      | Responsibility                              |
|-----------------------------|------------------------------------------------------------|---------------------------------------------|
| Infrastructure core         | Kubernetes, Cilium, Gateway API                            | Scheduling, networking, traffic in/out      |
| Platform services           | Vault, ESO, cert‑manager, Prometheus, Loki, Fluent‑bit     | Secrets, PKI, metrics, logs                 |
| Automation & governance     | ArgoCD, ApplicationSets, Kyverno, Policy Reporter          | GitOps, reconciliation, policies, compliance|
| Developer‑facing stacks     | Grafana, Pyrra, Argo Workflows, SonarQube, Trivy Operator  | Dashboards, pipelines, scanning             |

This layering is reflected in the repository layout and in the deployment order.

## GitOps backbone

The control plane operates through Git-driven automation across three layers. Bootstrap (`IT/`) handles one-time installation of core infrastructure including Cilium, Vault, ESO, cert-manager, ArgoCD, and Gateway API, along with minimal namespaces and RBAC. GitOps (`K8s/`) manages continuously reconciled state through stacks grouped by concern—observability, CI/CD, and security—with one ApplicationSet per stack that discovers subdirectories and generates ArgoCD Applications. Policies (`Policies/`) define Kyverno rules and related configuration.

ArgoCD applies all changes from these directories to the cluster. Manual cluster modifications are treated as drift and automatically reverted. For implementation details, see [GitOps model](../concepts/gitops-model.md) and [K8s directory architecture](applications.md).

## Resilience on a small cluster

High availability on a 3-node edge cluster requires a different approach than large cloud deployments. The design prioritizes tiered criticality: the core control plane (Kubernetes API and etcd) receives highest priority, critical infrastructure like ArgoCD and Prometheus must survive node loss, and everything else can degrade or restart later. Scheduling uses PriorityClasses to separate infrastructure from workloads, node labels to define pools (control plane, infra, workloads), and tolerations that allow critical components to use the control plane node as a lifeboat.

When a node fails, the platform preserves visibility through Prometheus and Loki while maintaining the ability to repair via ArgoCD, even if some stacks run in degraded mode. See [Scheduling, priority, and node pools](../concepts/scheduling-nodepools.md) and [Disaster recovery](../operate/disaster-recovery.md) for operational details.

## Selection criteria (why these technologies)

Components in this blueprint were chosen with a few strict constraints:

- **Good behavior under resource constraints**: avoid heavyweight stacks that assume many nodes.
- **Native declarative support**: first‑class Kubernetes CRDs and GitOps integration.
- **Healthy ecosystems**: CNCF or widely adopted open source projects.
- **No commercial licenses**: easy to adopt in labs and internal platforms.
- **Cloud‑agnostic**: work on bare metal, on‑prem, or public cloud.

The blueprint focuses on what must be provided at the platform layer (networking, security, observability, policy, GitOps). Cloud‑specific services are left out by design.

## Where to go next

From here, you can dig into specific views:

- **Bootstrap and infrastructure**: [IT directory architecture](infrastructure.md)
- **GitOps application layer**: [K8s directory architecture](applications.md)
- **Secrets and PKI**: [Secrets management architecture](secrets.md)
- **Policy and governance**: [Security & policy model](../concepts/security-policy-model.md)
- **Observability stack**: [Observability architecture](observability.md)
- **CI/CD stack**: [CI/CD architecture](cicd.md)

If you have not deployed the platform yet, read [Getting started](../getting-started/overview/) next and then come back here with a running cluster.
