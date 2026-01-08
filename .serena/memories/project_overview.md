# Project Overview & Architecture (validated 2025-12-27)

## Purpose & Scope
Open-source reference Internal Developer Platform (IDP) for local or lab Kubernetes (k3d by default). One-command deploy provides GitOps, policy, observability, CI/CD, and secrets management. (See `README.md`.)

## Core Components
- **GitOps**: ArgoCD + ApplicationSets
- **Networking**: Cilium CNI + Gateway API + cert-manager
- **Security**: Vault + External Secrets Operator + Kyverno + Trivy
- **Observability**: Prometheus Operator, Grafana, Loki, Fluent Bit, Pyrra
- **Portal**: Backstage
- **CI/CD**: Argo Workflows + SonarQube (feature-gated)

## Repository Layout
- `IT/`: Bootstrap layer (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway, namespaces, priority classes)
- `K8s/`: GitOps stacks (ApplicationSets discover subdirectories)
- `Policies/`: Kyverno policies (standalone ArgoCD Application)
- `Task/` and `Taskfile.yaml`: Orchestration
- `Scripts/`: Helpers (config extraction, env generation, Vault init/seed, validation)
- `Docs/`: Astro documentation site source
- `UI/`: Backstage portal source

## Deployment Flow (high level)
From `Taskfile.yaml` and `README.md`:
1. `task deploy` runs `internal:generate-env` to build `.env` from `config.toml`.
2. Bootstrap: k3d cluster, namespaces, CRDs, Cilium, cert-manager, Vault, External Secrets.
3. Install ArgoCD and Gateway.
4. Apply ApplicationSets for policies and stacks (`stacks:deploy`).

## Configuration Strategy
- **Single source**: `config.toml` (versions, fuses, NodePorts, repo overrides).
- **Env generation**: `Scripts/generate-env.sh` → `.env`.
- **Templating**: `envsubst` for DNS/IP/version placeholders before applying manifests.

## Feature Flags (`config.toml`)
`[fuses]` controls stack deployment:
- `policies`, `observability`, `cicd`, `security`, `backstage`, `prod`
