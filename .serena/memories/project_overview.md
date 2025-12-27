# Project Overview & Architecture (validated 2025-12-27)

## Purpose & Scope
- **Goal**: Open-source reference Internal Developer Platform (IDP) for local/lab Kubernetes.
- **Target**: Runs on laptop-class hardware (k3d) but mimics production architecture.
- **Stack**:
  - **GitOps**: ArgoCD + ApplicationSets.
  - **Networking**: Cilium (CNI) + Gateway API + cert-manager + nip.io (DNS).
  - **Security**: Vault (Secrets) + External Secrets Operator (ESO) + Kyverno (Policy) + Trivy.
  - **Observability**: Prometheus Operator, Grafana, Loki, Fluent Bit, Pyrra.
  - **IDP Portal**: Backstage.
  - **CI/CD**: Argo Workflows, SonarQube (optional).

## Repository Layout
- `IT/`: Bootstrap layer (Cluster, Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway).
- `K8s/`: GitOps stacks (ApplicationSets for policies, observability, backstage, cicd, security).
- `Catalog/`: Backstage catalog entities and component manifests.
- `Task/`: Taskfile modules orchestrating the workflow.
- `Scripts/`: Helpers for config, environment generation, vault init, and validation.
- `Docs/`: Documentation site (Astro/Starlight).
- `UI/`: Backstage portal source code.
- `config.toml`: Central configuration file (root). **Note:** Ignored by AI tools for security; contains demo credentials.

## Deployment Flow (`Taskfile.yaml`)
1. **Config**: `task deploy` calls `internal:generate-env` to read `config.toml` and generate `.env`.
2. **Core Deploy (`deploy-core`)**:
   - **Cluster**: `k3d` creation (1 server, 2 agents; ~12GB RAM total limit).
   - **Bootstrap**: Namespaces, CRDs, Cilium, cert-manager, Vault, ESO.
   - **GitOps Engine**: ArgoCD deployment.
   - **Ingress**: Gateway API setup.
   - **Stacks**: Policies and AppSets applied via ArgoCD.

## Configuration Strategy
- **Single Source of Truth**: `config.toml`.
- **Environment generation**: `Scripts/generate-env.sh` converts config to `.env`.
- **Templating**: `envsubst` is used client-side for dynamic values (DNS, IP, versions) before applying manifests. This hybrid approach allows portability across different environments/LAN IPs while maintaining GitOps principles for the rest.
- **Fuses**: Feature flags in `config.toml` (`[fuses]`) control which stacks deploy.

## Design Trade-offs & Constraints (Demo Mode)
- **Security Posture**:
  - `config.toml` ships with known demo credentials (must be rotated for real use).
  - **Vault**: Run in standalone mode, TLS disabled, unseal token stored in K8s Secret (key-shares=1).
- **Networking**:
  - Uses **NodePort** (30080/30443) mapped to host + **nip.io** wildcard DNS.
  - No external LoadBalancer or L2 announcements required.
- **Persistence**:
  - **Loki**: Filesystem backend with 24h retention and small PVCs (2Gi).
  - **Postgres**: Shared instance or ephemeral depending on component.
- **Observability**:
  - Control-plane metrics bound to `0.0.0.0` for single-node scraping.
- **Resource Sizing**:
  - Optimized for laptops: Many components are single-replica.
  - **Requirements**: Minimum 4 vCPU / 8 GiB RAM; Recommended 6 vCPU / 12 GiB RAM.

## Development Tooling
- **Devbox**: Manages all dependencies (`kubectl`, `helm`, `k3d`, `argocd`, `cilium`, `task`, etc.) in `devbox.json`.
- **Validation**: `validate-tools` task ensures environment readiness.