# Project Overview + Taskfile Design (validated 2025-12-27)

## Purpose & scope
- Open-source reference IDP for local/lab Kubernetes (k3d by default).
- Ships GitOps (ArgoCD + ApplicationSets), policy (Kyverno + Policy Reporter), networking (Cilium + Gateway API + nip.io), secrets (Vault + ESO), observability (Prometheus Operator, Grafana, Loki, Fluent Bit, Pyrra), optional CI/CD (Argo Workflows, SonarQube), Backstage.

## Repo layout (current)
- `IT/` bootstrap layer (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway, namespaces, priority classes).
- `K8s/` GitOps stacks (ApplicationSets for policies, observability, backstage, cicd, security, events).
- `Catalog/` Backstage catalog entities.
- `Task/` Taskfile modules; `Taskfile.yaml` orchestrates.
- `Scripts/` helpers (config, vault init/seed, validation, docs).
- `Docs/` Astro/Starlight documentation site.
- `UI/` Backstage portal.

## Deployment flow (Taskfile)
- `task deploy` → `internal:generate-env` → `deploy-core`.
- `deploy-core` sequence:
  1) k3d create
  2) namespaces/priorities/CRDs
  3) Cilium
  4) cert-manager + Vault
  5) External Secrets
  6) ArgoCD
  7) Gateway
  8) policies AppSet
  9) stacks AppSets

## Config + env design
- **Single source**: `config.toml` → `Scripts/generate-env.sh` → `.env`.
- `task deploy` exports `.env` via `set -a && . ./.env && set +a` to keep a consistent runtime.
- **envsubst** renders templates client‑side (k3d config, AppSets/AppProjects, Gateway, Backstage config). Keeps portability but is not pure GitOps.
- **Fuses**: `FUSE_*` derived from `[fuses]` in `config.toml`; used as `status` gates in `Task/stacks.yaml`.
- `validate-tools` ensures key binaries exist before running deployment steps.

## Dev tooling
- Devbox-managed toolchain (kubectl, helm, kustomize, k3d, argocd, cilium, yamllint, shellcheck, hadolint, markdownlint, checkov, trufflehog, helm-docs, etc.).

## Resources (recommended)
- Minimum: 4 vCPU / 8 GiB RAM.
- Comfortable: 6 vCPU / 12 GiB RAM.
- Disk: ~20 GiB free.