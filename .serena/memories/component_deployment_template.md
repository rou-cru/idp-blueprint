# Component Authoring & Conventions (validated 2025-12-27)

## Stack/AppSet pattern (repo)
- ApplicationSets live in `K8s/<stack>/applicationset-<stack>.yaml` and use git generator `K8s/<stack>/*`.
- Template name: `<stack>-{{path.basename}}`, project `<stack>`, namespace `<stack>`.
- `Task/stacks.yaml` applies each AppSet via `envsubst` and gates with `FUSE_*` from `config.toml`.

## Expected stack structure
- `applicationset-<stack>.yaml`
- `governance/` (namespace/quota/limitrange; namespace sync-wave -2)
- `infrastructure/` (SecretStore/ESO if applicable)
- component dirs with `kustomization.yaml`, `values.yaml`/`Chart.yaml` or manifests; README recommended

## Labels & priorities (source of truth)
- Labels standard: `Docs/src/content/docs/reference/labels-standard.mdx`.
- Namespace labels required: `app.kubernetes.io/part-of`, `owner`, `business-unit`, `environment`.
- PriorityClasses defined in `IT/priorityclasses/priorityclasses.yaml`.

## Resources & units
- Workloads should set CPU/memory requests & limits using `m` and `Mi/Gi`.
- Cilium agent may lack limits based on chart defaults.

## SecretStores/ESO pattern
- SecretStore per namespace → Vault `http://vault.vault-system.svc.cluster.local:8200` (demo) + role `eso-<ns>-role`.
- ExternalSecret default `creationPolicy: Owner`; ArgoCD uses Merge/Retain.

## Doc/test helpers
- Regenerate docs/metadata after values changes: `task docs`, `task docs:helm`, `task docs:metadata`.
- Validate render: `kustomize build K8s/<stack>/<component>` or `helm template`.
- Confirm config: `task utils:config:print`.