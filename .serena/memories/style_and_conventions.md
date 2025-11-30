# Style and Conventions

- **Atomic commits**: one logical change per commit to keep `git bisect` effective.
- **Resource limits/requests mandatory** on all workloads; use explicit units (CPU in millicores like `500m`, memory `Mi/Gi`). Exception: cilium-agent intentionally without limits.
- **Label standards**: follow `Docs/src/content/docs/reference/labels-standard.md`; namespaces must include `app.kubernetes.io/part-of`, `owner`, `business-unit`, `environment`. Canonical values: owner=platform-team, business-unit=infrastructure, environment=demo, app.kubernetes.io/part-of=idp.
- **Helm values documentation**: use `helm-docs` annotations; comments directly above params start with `# --`, sections with `## @section`, optional defaults with `# @default -- value`.
- **Architecture layout**: Infrastructure bootstrap in `IT/` (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway); application stacks in `K8s/` with ArgoCD App-of-AppSets; policies in `Policies/` (Kyverno engine + rules).
- **Tooling expectations**: Develop inside Devbox or Dev Container so required CLIs (kubectl, helm, kustomize, yamllint, shellcheck, hadolint, markdownlint, checkov, trufflehog, helm-docs, k3d, ArgoCD CLI, etc.) are preinstalled.
- **Documentation**: Docs site uses Astro/Starlight under `Docs/` (pnpm workspace). Use `task utils:docs` to regenerate metadata/helm-docs when values change.
