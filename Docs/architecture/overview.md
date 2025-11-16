# Architecture overview

This page describes the main architectural elements of IDP Blueprint and how they fit together. It assumes you know Kubernetes basics and want to understand how this IDP is wired as a system.

For the product‑level mental model and feedback loops, see [Concepts](../concepts/index.md). Here we stay at the C4 “System Context” (L1) and “Container” (L2) levels; detailed C4 component (L3) views live in the other Architecture pages.

## Context and goals

IDP Blueprint is designed for:

- Kubernetes clusters where you want a compact, self‑hosted platform stack (the reference demo uses a 3‑node k3d cluster by default).
- Edge/on‑prem or constrained environments where scaling out is not the main option, but the same architecture applies to larger clusters.
- GitOps‑first operation: Git is the source of truth, ArgoCD reconciles the cluster.
- Cloud‑agnostic use: no managed control planes and no commercial licenses.

Typical uses:

- Evaluate a realistic platform stack on a laptop or lab cluster.
- Prototype an internal developer platform without committing to a vendor.
- Train platform, SRE, and security engineers on GitOps and policy‑driven operation.

## System context (C4 L1)

At the highest level, the platform sits between engineers, Git, and a Kubernetes cluster:

- **Actors**
  - Platform engineers operate the IDP (bootstrap, upgrades, policies, SLOs).
  - Application teams deploy workloads onto the platform.
- **External systems**
  - Git: source of truth for bootstrap config, GitOps stacks, policies, and SLOs.
  - Container registry: stores container images for platform components and workloads.
  - Optional cloud services: external secret managers or backing services.
- **Deployment target**
  - A single Kubernetes cluster (local or remote), treated as an implementation detail.

Everything is driven from Git: changes are pushed to the repo, ArgoCD reconciles the cluster, and observability feeds back into decisions.

```d2
direction: right

PlatformEngineer: {
  label: "Platform Engineer"
  shape: c4-person
}

Developer: {
  label: "Application Developer"
  shape: c4-person
}

Git: {
  label: "Git provider\n(bootstrap, stacks, policies)"
  shape: rectangle
}

Registry: {
  label: "Container registry"
  shape: rectangle
}

IDPSystem: {
  label: "IDP Blueprint\n(System)"
  shape: rectangle
}

PlatformEngineer -> Git
Developer -> Git

Git -> IDPSystem: "manifests via ArgoCD"
Registry -> IDPSystem: "images"
Developer -> IDPSystem: "use UIs & APIs"
```

## Container view (C4 L2)

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

Core: {
  label: "0. Infrastructure core"
  K8s: "Kubernetes API + etcd"
  Cilium: "Cilium CNI"
  Gateway: "Gateway API"
}

Services: {
  label: "1. Platform services"
  Vault
  ESO: "External Secrets Operator"
  Cert: "cert-manager"
  Prom: "Prometheus"
  Loki
  FluentBit: "Fluent-bit"
}

Governance: {
  label: "2. Automation & governance"
  ArgoCD
  AppSets: "ApplicationSets"
  Kyverno
  PolicyReporter: "Policy Reporter"
}

Stacks: {
  label: "3. Developer-facing stacks"
  Grafana
  Pyrra
  Workflows: "Argo Workflows"
  Sonar: "SonarQube"
  Trivy: "Trivy Operator"
}
```

## Platform layers

The same components can be viewed as a set of logical layers:

| Layer                         | Components (examples)                                                   | Responsibility                                                |
|-------------------------------|-------------------------------------------------------------------------|---------------------------------------------------------------|
| **0. Infrastructure core**    | Kubernetes, Cilium, Gateway API                                        | Scheduling, networking, traffic in/out                       |
| **1. Platform services**      | Vault, ESO, cert‑manager, Prometheus, Loki, Fluent‑bit                 | Secrets, PKI, metrics, logs                                  |
| **2. Automation & governance**| ArgoCD, ApplicationSets, Kyverno, Policy Reporter                      | GitOps, reconciliation, policies, compliance                 |
| **3. Developer‑facing stacks**| Grafana, Pyrra, Argo Workflows, SonarQube, Trivy Operator              | Dashboards, pipelines, scanning                              |

This layering is reflected in the repository layout and in the deployment order.

## GitOps backbone

The control plane of this IDP is Git‑driven:

- Bootstrap (`IT/`) brings up:
  - Cilium, Vault, ESO, cert‑manager, ArgoCD, Gateway API.
  - Minimal namespaces and RBAC to host platform components.
- GitOps (`K8s/`) defines:
  - Stacks grouped by concern (observability, CI/CD, security).
  - One ApplicationSet per stack; each ApplicationSet discovers subdirectories and creates ArgoCD Applications.
- Policies (`Policies/`) define:
  - Kyverno policies and related configuration.

Changes to any of these folders are applied through ArgoCD. Manual changes in the cluster are treated as drift and reverted.

For a deeper look at this control backbone, see [GitOps model](../concepts/gitops-model.md) and [K8s directory architecture](applications.md).

## Resilience on a small cluster

On a 3‑node edge cluster, high availability looks different from large cloud setups. The design focuses on:

- **Tiered criticality**
  - Core control plane (Kubernetes API, etcd) is highest priority.
  - Critical infrastructure (ArgoCD, Prometheus) must survive node loss.
  - Everything else can be degraded or restarted later.
- **Scheduling and priorities**
  - PriorityClasses separate infrastructure from workloads.
  - Node labels enable “pools” (control plane, infra, workloads).
  - Tolerations let critical components use the control plane node as a lifeboat.

When a node fails, the goal is to preserve visibility (Prometheus, Loki) and the ability to repair (ArgoCD) even if some stacks are degraded.

See [Scheduling, priority, and node pools](../concepts/scheduling-nodepools.md) and [Disaster recovery](../operate/disaster-recovery.md) for details.

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

If you have not deployed the platform yet, read [Getting started](../getting-started/overview.md) next and then come back here with a running cluster.
