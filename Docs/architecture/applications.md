# K8s directory architecture — GitOps with ApplicationSets

This document outlines the GitOps strategy for managing all applications and services
(workloads) deployed on the cluster. This directory (`K8s/`) is the source of truth,
managed exclusively by ArgoCD.

From a C4 perspective this page provides a **component view (L3)** of the GitOps application layer (“2. Automation & governance” and “3. Developer‑facing stacks” in the overview).

## Core Pattern: App of AppSets

We employ a modular, scalable pattern where multiple `ApplicationSet` resources are used
instead of a single monolithic one. This provides flexibility, clear ownership, and
reduces the blast radius of any configuration errors.

- **One `ApplicationSet` per Stack:** Each primary directory within `K8s/` (e.g.,
  `observability/`, `cicd/`) represents a "stack" of tools. Each stack contains its own
  `applicationset-<stack>.yaml` file.
- **`ApplicationSet` Role:** This file is responsible for discovering and managing all
  applications _within its own stack directory_.
- **Root `Application`:** A root ArgoCD `Application` (managed outside this directory)
  is responsible for deploying the `ApplicationSet` resources themselves.

### GitOps Workflow Diagram

This diagram illustrates the entire flow, from the Git repository to the deployed
applications in their respective namespaces.

```d2
direction: right

Git: {
  label: "Git Repository (K8s/)"
  Root: "Root App"
}

Argo: {
  label: "ArgoCD"
  AppSetCICD: "AppSet-CICD"
  AppSetObs: "AppSet-Observability"
  AppSetSec: "AppSet-Security"
  DiscWF: "argo-workflows/"
  DiscLoki: "loki/"
  DiscProm: "prometheus/"
}

Cluster: {
  label: "Kubernetes Cluster"
  NSCICD: "Namespace: cicd"
  NSOBS: "Namespace: observability"
}

Git.Root -> Argo.AppSetCICD: deploys
Git.Root -> Argo.AppSetObs: deploys
Git.Root -> Argo.AppSetSec: deploys
Argo.AppSetCICD -> Argo.DiscWF: discovers
Argo.AppSetObs -> Argo.DiscLoki: discovers
Argo.AppSetObs -> Argo.DiscProm: discovers
Argo.DiscWF -> Cluster.NSCICD: deploys to
Argo.DiscLoki -> Cluster.NSOBS: deploys to
Argo.DiscProm -> Cluster.NSOBS: deploys to
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
  - A `values.yaml` file (e.g. `argo-workflows-values.yaml`) contains all custom
        configuration for that chart.

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
        valuesFile: argo-workflows-values.yaml
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
    - **Components**: Cilium, Cert-Manager, Vault, ArgoCD.
    - **Method**: These components are deployed imperatively via
      `helm upgrade` tasks within the `Taskfile.yaml`.
    - **Version Source**: Their chart versions are centralized in the `vars:` section of
      the `Taskfile.yaml`. This allows for top-level control over
      critical infrastructure versions.

2. **Application Stack Components (Managed by GitOps)**
    - **Components**: Argo Workflows, SonarQube, Loki, Prometheus, Trivy, etc.
    - **Method**: These components are deployed declaratively by ArgoCD via
      `ApplicationSet` resources.
    - **Version Source**: The Helm chart version is specified directly in each
      application's respective `kustomization.yaml` file.
      This approach keeps an application's entire configuration,
      including its version, co-located in a single place,
      adhering to GitOps principles.
