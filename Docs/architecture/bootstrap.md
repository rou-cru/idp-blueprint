# IT Directory Architecture

This directory contains the **static / bootstrap layer** of the platform. Everything
here must exist _before_ ArgoCD can reconcile Git.

## Guiding Principles

The structure follows two simple rules to keep things predictable.

### 1. Helm Chart Configurations

Configuration for a core component deployed via a Helm chart is defined in a single
`*-values.yaml` file.

- **Location**: Root of the `IT/` directory.
- **Naming**: The filename is simple and references the component (e.g.,
  `cilium-values.yaml`, `vault-values.yaml`).

### 2. Raw Kubernetes Manifests

Static Kubernetes resources that are not part of a Helm chart installation (e.g., a
`ClusterIssuer` or a `ClusterSecretStore`) are organized as raw YAML files.

- **Location**: Placed inside a subdirectory named after the parent component (e.g.,
  `cert-manager/`).
- **Naming**: The filename **must** exactly match the `metadata.name` of the resource
  defined within it (e.g., a `ClusterIssuer` with `name: ca-issuer` is saved in
  `ca-issuer.yaml`).

### 3. Bootstrap Resources via Kustomize

Some components require orchestrated deployment of multiple resources. We wrap them in
Kustomize and apply them with `kustomize build <dir>/ | kubectl apply -f -`.

- **Location**: Subdirectories with their own `kustomization.yaml`.
- **Purpose**:
  - `namespaces/`: Bootstrap namespace definitions for core components.
  - `cert-manager/`: Issuers and Certificate definitions.
  - `external-secrets/`: The `ClusterSecretStore` to connect to Vault and
    the `ExternalSecret` for ArgoCD.
  - `argocd/`: Kustomization to support the Helm chart.

## Directory layout (short)

The `IT/` directory is intentionally flat at the top level:

```text
IT/
├── k3d-cluster.yaml
├── kustomization.yaml
├── argocd-values.yaml
├── cert-manager-values.yaml
├── cilium-values.yaml
├── eso-values.yaml
├── vault-values.yaml
├── namespaces/
├── cert-manager/
├── external-secrets/
├── vault/
└── argocd/
```

## Quick Reference

| Path | Purpose | Type |
| --- | --- | --- |
| `k3d-cluster.yaml` | Defines the k3d topology (1 server + 2 agents + registry cache). | k3d Config |
| `kustomization.yaml` | Root orchestrator (currently minimal but future-proof). | Kustomize |
| `*-values.yaml` | Helm chart configuration for each bootstrap dependency. | Helm Values |
| `namespaces/` | Namespaces + labels required before workloads land. | Kustomize Bootstrap |
| `vault/` | Manual init / unseal helpers (e.g., `vault-manual-init.sh`). | Shell Script |
| `cert-manager/` | ClusterIssuers, CA certificates, Gateway-friendly resources. | Raw Manifests |
| `external-secrets/` | `ClusterSecretStore` + initial `ExternalSecret` objects. | Raw Manifests |
| `argocd/` | Kustomize glue (RBAC, AppProjects) that supplements Helm. | Kustomize |

## Deployment Workflow

### Bootstrap Timeline

```d2
shape: sequence_diagram
Task: task deploy
K3d: k3d cluster
NS: Namespaces
Cilium: Cilium
CRDs: Prometheus CRDs
CM: cert-manager
Vault: Vault (deploy + init)
ESO: External Secrets Operator
Argo: ArgoCD
GW: Gateway API
Kyverno: Policies (Kyverno)
Stacks: Application stacks (AppSets)

Task -> K3d: Create cluster
Task -> NS: Apply namespaces
Task -> Cilium: Install CNI
Task -> CRDs: Install operator CRDs
Task -> CM: Install + apply issuers/certs
Task -> Vault: Deploy and init
Task -> ESO: Install ESO
Task -> Argo: Deploy ArgoCD
Task -> GW: Apply Gateway
Task -> Kyverno: Deploy policies
Task -> Stacks: Sync stacks (observability, cicd, security)
```

### Expanded Steps

1. **Create the cluster** via `k3d-cluster-cached.yaml` (built-in registry cache keeps re-deployments snappy).
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
