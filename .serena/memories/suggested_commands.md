# Suggested Commands

## Environment
- Start dev environment with Devbox: `devbox shell` (tooling auto-installed).
- VS Code Dev Container also supported; repo already configured.

## Main workflows
- Deploy full platform on k3d: `task deploy`
- Destroy k3d cluster/registry: `task destroy`
- Recreate from scratch: `task redeploy`
- Deploy only GitOps stacks (after bootstrap already up): `task stacks:deploy`
- Print effective config (repo, revision, cluster, ports, fuses): `task utils:config:print`

## Quality / validation
- Run full gate (lint + validate + security): `task quality:check`
- Linters only: `task quality:lint` (includes yaml, shell, Dockerfile, markdown, helm-docs check)
- Kustomize + kubeval schema validation: `task quality:validate`
- IaC misconfig scan: `task quality:security:iac`
- Secret scan: `task quality:security:secrets`
- Commit message lint: `task quality:lint:commit`

## Docs
- Build docs site (Astro/Starlight): `task docs:astro:build`
- Serve docs locally: `task docs:astro:dev`
- Generate chart metadata and helm-docs: `task utils:docs`
- Check docs links: `task utils:docs:linkcheck`

## Utilities
- Export cluster CA for browser import: `task utils:ca:export`
- Generate only helm-docs: `task utils:docs:helm`
- Generate only Chart.yaml metadata: `task utils:docs:metadata`

## Bootstrapping internals (usually invoked by deploy)
- Create k3d cluster + registry: `task k3d:k3d:create`
- Apply infrastructure baseline (namespaces, cert-manager, Vault, ESO, ArgoCD, gateway, policies): `task bootstrap:it:bootstrap` etc. Usually do not run directly unless debugging.
