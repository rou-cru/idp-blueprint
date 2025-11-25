---
title: Application Architecture
sidebar:
  label: Applications
  order: 8
---

> **Context:** This page details the technical implementation of the [GitOps model](../concepts/gitops-model.md)
  based
  on the [GitOps philosophy](../concepts/design-philosophy.md#3-gitops).

This document outlines the GitOps strategy for managing all applications and services
  (workloads) deployed on the cluster. This directory (`K8s/`) is the source of truth,
  managed exclusively by ArgoCD.

This page provides a component view of the GitOps application layer (automation/governance
  and developer‑facing stacks).

## Core Pattern: App of AppSets

We employ a modular, scalable pattern where multiple `ApplicationSet` resources are used
instead of a single monolithic one. This provides flexibility, clear ownership, and
reduces the blast radius of any configuration errors.

- **One `ApplicationSet` per Stack:** Each primary directory within `K8s/` (e.g.,
  `observability/`, `cicd/`) represents a "stack" of tools. Each stack contains its own
  `applicationset-<stack>.yaml` file.
- **`ApplicationSet` Role:** This file is responsible for discovering and managing all
  applications _within its own stack directory_.
- **Root `Application`:** A root ArgoCD `Application` (managed outside this
  directory) is responsible for deploying the `ApplicationSet` resources themselves.

### GitOps Workflow Diagram

```d2
direction: right

classes: { git: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           ns: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Git: { class: git; label: "Git repo\nK8s/" }

Argo: {
  class: control
  label: "ArgoCD (app-of-appsets)"
  AppSets: {
    CICD: "ApplicationSet: cicd"
    OBS: "ApplicationSet: observability"
    SEC: "ApplicationSet: security"
    EVENTS: "ApplicationSet: events"
    DP: "ApplicationSet: backstage"
  }
}

Cluster: {
  class: ns
  label: "Namespaces"
  CICD: "cicd"
  OBS: "observability"
  SEC: "security"
  EVENTS: "events"
  DP: "backstage"
}

Git -> Argo: "Root app\n(manages AppSets)"
Argo.AppSets.CICD -> Cluster.CICD: "generate apps\nargo-workflows/, sonarqube/"
Argo.AppSets.OBS -> Cluster.OBS: "generate apps\nloki/, kube-prometheus-stack/"
Argo.AppSets.SEC -> Cluster.SEC: "generate apps\ntrivy-operator/"
Argo.AppSets.EVENTS -> Cluster.EVENTS: "generate apps\nargo-events/"
Argo.AppSets.DP -> Cluster.DP: "generate apps\nbackstage/"
```

## Bootstrap and Standalone Applications

Certain foundational, cross-cutting components like the policy engine are deployed
first, before the main application stacks. This ensures the cluster's "rules of the
road" are active before other workloads are deployed.

- **Policy Stack:** The policy engine (Kyverno) and the policies themselves are managed
  by a standalone ArgoCD `Application` defined in `Policies/app-kyverno.yaml`. This
  application is deployed directly during the bootstrap phase (e.g., via
  `Taskfile.yaml`) and points to the `Policies/` directory, which uses Kustomize to
  orchestrate the deployment of the entire stack.

This approach provides a secure bootstrap process at the cost of being a slight
exception to the general "App of AppSets" pattern.

## Directory structure (short)

The `K8s/` directory mirrors the stack and namespace strategy:

```text
K8s/
├── cicd/
│   ├── applicationset-cicd.yaml
│   ├── namespace.yaml
│   ├── argo-workflows/
│   │   └── kustomization.yaml
│   └── governance/
│       └── kustomization.yaml
├── observability/
│   ├── applicationset-observability.yaml
│   ├── namespace.yaml
│   ├── loki/
│   │   └── kustomization.yaml
│   └── kube-prometheus-stack/
│       └── kustomization.yaml
└── security/
    ├── applicationset-security.yaml
    └── namespace.yaml
```

- `namespace.yaml`: defines the stack namespace and common labels/annotations.
- `applicationset-<stack>.yaml`: ApplicationSet that discovers apps within the stack.
- `<app-name>/kustomization.yaml`: Kustomize entrypoint for a component; ArgoCD targets this file.

## Application Manifests & Kustomize

To manage the complexity of modern applications, we use **Kustomize** as the standard
for defining and composing application manifests. Our philosophy is based on
**resource composition** over complex inheritance via `overlays`.

Two primary patterns for Kustomize are established in this project.

### Pattern 1: local resource aggregation

This is the standard approach for **in-house applications** or for grouping a set of
related Kubernetes manifests.

- **When to Use It:** For internally developed microservices, governance policies
    (`ResourceQuota`, `LimitRange`), or any set of YAML manifests you manage directly.
- **Structure:**
  - A directory is created for the component (e.g., `governance/`).
  - YAML files (`limitrange.yaml`, `resourcequota.yaml`) are placed inside.
  - The `kustomization.yaml` file lists them in the `resources` section.

- **Example (`K8s/cicd/governance/kustomization.yaml`):**

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - limitrange.yaml
      - resourcequota.yaml
    ```

### Pattern 2: Helm chart orchestration

This is the **preferred, standard method** for deploying **third-party applications**
or any software available as a Helm chart. It allows us to version and manage the
configuration of these tools declaratively.

- **When to Use It:** For tools like Argo Workflows, Loki, Prometheus, Trivy, etc.
- **Structure:**
  - A directory is created for the application (e.g., `argo-workflows/`).
  - A `kustomization.yaml` file defines the Helm chart in the `helmCharts` section.
  - A `values.yaml` file contains all custom configuration for that chart.

- **Example (`K8s/cicd/argo-workflows/kustomization.yaml`):**

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    helmCharts:
      - name: argo-workflows
        repo: https://argoproj.github.io/argo-helm
        version: 0.45.11
        releaseName: argo-workflows
        namespace: cicd
        valuesFile: values.yaml
    ```

## Workflow for Deploying a New Application

1. **Choose the Stack:** Identify which stack the new application belongs to (e.g.,
    `observability`).
2. **Create a Directory:** Create a new subdirectory for your application (e.g.,
    `K8s/observability/my-new-app/`).
3. **Add Manifests:** Add all Kubernetes manifest files for your application to this
    new directory.
4. **Create `kustomization.yaml`:** Add a `kustomization.yaml` file that lists all the
    manifest files you just created.
5. **Commit & Push:** Commit your changes to Git. The corresponding `ApplicationSet`
    will automatically detect the new directory and deploy your application into the
    correct namespace.

## Component Versioning Strategy

The project uses a two-tiered strategy for managing Helm chart versions,
depending on how each component is deployed:

1. **Core Infrastructure Components (Managed by `Taskfile.yaml`)**
    - **Components**: Cilium, cert-manager, Vault, ArgoCD.
    - **Method**: Deployed imperatively via `helm upgrade` tasks in the bootstrap Taskfile.
    - **Version Source**: `config.toml [versions]` (e.g., `cilium`, `cert_manager`, `vault`, `argocd`).
      Tasks read these values through `Scripts/config-get.sh`, so changing the TOML is the single point to pin or bump chart versions.

2. **Application Stack Components (Managed by GitOps)**
    - **Components**: Argo Workflows, SonarQube, Loki, Prometheus, Trivy, etc.
    - **Method**: These components are deployed declaratively by ArgoCD via
      `ApplicationSet` resources.
    - **Version Source**: The Helm chart version is specified directly in each
      application's respective `kustomization.yaml` file.
      This approach keeps an application's entire configuration,
      including its version, co-located in a single place,
      adhering to GitOps principles.
