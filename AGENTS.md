# Repository Guidelines

## Project Structure & Module Organization
Bootstrap assets live in `IT/`, covering namespaces, service accounts, priority classes, Cilium, Vault, External Secrets, and Gateway definitions; treat this folder as the source of truth for anything that must exist before ArgoCD starts. GitOps workload specs sit under `K8s/` (`observability`, `cicd`, `security`, `vault`) and are wired through ApplicationSets referenced in `K8s/argocd`. Kyverno rules, Policy Reporter manifests, and supporting docs live in `Policies/`. Task automation resides in `Taskfile.yaml`, helper utilities in `Scripts/`, and background material (architecture, label standards) now lives under `docs/` (see `docs/architecture/visual.md`, `docs/reference/labels-standard.md`). Co-locate new Helm values and overlays beside their owning stack to keep App-of-AppSets diffs localized.

## Build, Test, and Development Commands
- `task deploy` – provisions the entire IDP onto the k3d cluster defined in `IT/k3d-cluster-cached.yaml`.
- `task destroy` – removes the `idp-demo` cluster; run after experiments to free ports and RAM.
- `task stacks:deploy` / `task policies:deploy` – redeploy a single ApplicationSet layer without re-bootstrapping.
- `task lint`, `task validate:kubeval`, `task check` – run linters, schema validation, and security scanners (yamllint, shellcheck, kubeval, checkov, trufflehog).
- `./Scripts/helm-docs-lint.sh` and `./Scripts/validate-consistency.sh` – ensure Helm comment syntax, canonical labels, and priority class coverage stay in sync before opening a PR.

## Coding Style & Naming Conventions
Use two-space indentation for YAML/Kustomize and keep resource blocks ordered `apiVersion`, `kind`, `metadata`, `spec`. Every workload must define CPU/memory requests and limits; never commit unitless numbers. Follow the Helm-docs comment style (`## @section`, `# -- description`, `# @default -- value`) so generated documentation stays accurate. Namespaces and charts must carry the canonical labels from `docs/reference/labels-standard.md` (`owner: platform-team`, `business-unit: infrastructure`, etc.); Application files follow `app-<component>.yaml` while Helm values stick to `*-values.yaml`.

## Testing Guidelines
Always run `task check` locally; it chains lint, schema validation, and security scans. For targeted iterations, `task lint:yaml`, `task lint:shell`, and `task validate:kustomize` keep overlays buildable. Execute `./Scripts/validate-consistency.sh` whenever you touch labels or `values.yaml` files, and rerun `./Scripts/helm-docs-lint.sh` after editing comments. Full-stack changes should be sanity-checked with `task deploy` followed by a quick `kubectl get applications -n argocd` to confirm sync.

## Commit & Pull Request Guidelines
Match the existing history: short, imperative subjects (`Add Kyverno pod-security policy`), optionally suffixed with `(#<issue>)`. Keep commits atomic—separate policy, chart, and script changes so `git bisect` remains useful. PRs should include context, screenshots or command output when touching UI surfaces (Grafana, ArgoCD), and a checklist confirming `task check`/`task deploy` results plus any follow-up cleanup (`task destroy`). Link related docs (`docs/architecture/bootstrap.md`, `docs/architecture/gitops.md`) when introducing new modules.

## Security & Configuration Tips
Never hard-code secrets; instead, document expected keys in `docs/architecture/secrets.md` and rely on the Vault helper scripts (`Scripts/vault-init.sh`, `Scripts/vault-generate.sh`). If you introduce new external endpoints or credentials, update the relevant Kyverno rules in `Policies/rules/` and the label source of truth in `IT/kustomization.yaml` so automation and Policy Reporter remain consistent.
