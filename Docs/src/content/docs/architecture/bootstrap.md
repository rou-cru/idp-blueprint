---
title: Bootstrap Layer
sidebar:
  label: Bootstrap
  order: 2
---

This directory contains the **static / bootstrap layer** of the platform. Everything here
  must exist _before_ ArgoCD can reconcile Git.

:::note[Related Documentation]
The components are the same as in the infrastructure core. This page focuses on their **lifecycle over time** (bootstrap sequence). For the **structural view** of the same components, see [Infrastructure Core](infrastructure.md).
:::

## Guiding Principles

The structure follows two simple rules to keep things predictable.

### 1. Helm Chart Configurations

Configuration for a core component deployed via a Helm chart is defined in a single
`*-values.yaml` file.

- **Location**: Root of the `IT/` directory.
- **Naming**: The filename is simple and references the component (e.g.,
  `values.yaml`).

### 2. Raw Kubernetes Manifests

Static Kubernetes resources that are not part of a Helm chart installation (e.g., a
`ClusterIssuer` or a `ClusterSecretStore`) are organized as raw YAML files.

- **Location**: Placed inside a subdirectory named after the parent component (e.g.,
  `cert-manager/`).
- **Naming**: The filename **must** exactly match the `metadata.name` of the resource
  defined within it (e.g., a `ClusterIssuer` with `name: ca-issuer` is saved
  in `ca-issuer.yaml`).

### 3. Bootstrap Resources via Kustomize

Some components require orchestrated deployment of multiple resources. We wrap them in
Kustomize and apply them with `kustomize build <dir>/ | kubectl apply -f -`.

- **Location**: Subdirectories with their own `kustomization.yaml`.
- **Purpose**:
  - `namespaces/`: Bootstrap namespace definitions for core components.
  - `cert-manager/`: Issuers and Certificate definitions.
  - `external-secrets/`: The `ClusterSecretStore` to connect to Vault and the
    `ExternalSecret` for ArgoCD.
  - `argocd/`: Kustomization to support the Helm chart.

## Directory layout (short)

The `IT/` directory is intentionally flat at the top level:

```text
IT/
├── k3d-cluster.yaml
├── kustomization.yaml
├── namespaces/
├── cert-manager/
│   └── values.yaml
├── external-secrets/
│   └── values.yaml
├── vault/
│   └── values.yaml
└── argocd/
    └── values.yaml
```

## Quick Reference

| Path | Purpose | Type |
| --- | --- | --- |
| `k3d-cluster.yaml` | Defines the k3d topology (1 server + 2 agents) including the local registry cache. | k3d Config |
| `kustomization.yaml` | Root orchestrator (currently minimal but future-proof). | Kustomize |
| `*-values.yaml` | Helm chart configuration for each bootstrap dependency. | Helm Values |
| `namespaces/` | Namespaces + labels required before workloads land. | Kustomize Bootstrap |
| `vault/` | Manual init / unseal helpers (e.g., `vault-manual-init.sh`). | Shell Script |
| `cert-manager/` | ClusterIssuers, CA certificates, Gateway-friendly resources. | Raw Manifests |
| `external-secrets/` | `ClusterSecretStore` + initial `ExternalSecret` objects. | Raw Manifests |
| `argocd/` | Kustomize glue (RBAC, AppProjects) that supplements Helm. | Kustomize |

## Deployment Workflow

### Bootstrap timeline

```d2
direction: right

classes: { step: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white } }

Flow: {
  class: step
  Task: "task deploy"
  K3d: "Create k3d cluster"
  NS: "Bootstrap namespaces"
  Cilium: "Install Cilium"
  CRDs: "Prometheus CRDs"
  Cert: "cert-manager + issuers"
  Vault: "Vault (init/unseal)"
  ESO: "External Secrets Operator"
  Argo: "ArgoCD + AppProjects"
  Gateway: "Gateway API + wildcard cert"
  Kyverno: "Kyverno + Policy Reporter"
  Stacks: "Sync stacks (obs/sec/cicd/backstage)"
}

Flow.Task -> Flow.K3d -> Flow.NS -> Flow.Cilium -> Flow.CRDs -> Flow.Cert -> Flow.Vault -> Flow.ESO -> Flow.Argo -> Flow.Gateway -> Flow.Kyverno -> Flow.Stacks
```

### Expanded Steps

1. **Create the cluster** via `k3d-cluster.yaml` (includes a local registry cache to speed re-deployments).
2. **Apply namespaces** so priority classes, quotas, and Kyverno label policies have a home.
3. **Install Cilium** to replace the default CNI and enable the Gateway API dataplane.
4. **Lay down Prometheus CRDs** using `prometheus-operator-crds` so later Helm releases skip CRD churn.
5. **Install cert-manager** and immediately apply issuers/certificates from `cert-manager/`.
6. **Deploy Vault** and run `Scripts/vault-init.sh` to unseal, store tokens, and enable Kubernetes auth.
7. **Deploy External Secrets Operator** and apply `external-secrets/` to wire Vault → Kubernetes → ArgoCD.
8. **Deploy ArgoCD** (Helm) plus AppProjects from `IT/argocd/`.
9. **Apply the Gateway** (Kustomize) to expose HTTPS endpoints backed by cert-manager.
10. **Apply Policies** (Kyverno + Policy Reporter) so governance exists before workloads.
11. **Let ApplicationSets run**—ArgoCD handles stacks in `K8s/` automatically once the controller is online.

**Key insight:** Everything above runs from `task deploy`, proving that a laptop-friendly IDP still benefits from strict boot order and clearly separated ownership.
