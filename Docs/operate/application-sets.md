---
# ApplicationSets Patterns — Many apps, one generator

ApplicationSets turn folder structure into Applications. One commit → one rollout.

## Generators

- Directory generator: map `K8s/<stack>/*` → Applications.
- List/cluster generators (future): multi-cluster fan‑out.

## Templates that matter

- Common labels/annotations; sync options (`ServerSideApply`, `PruneLast`).
- Automated prune + self‑heal; retries with backoff.
- `ignoreDifferences` for noisy fields (e.g., webhook `caBundle`).

## Validate before merging

- Dry‑run locally; preview in ArgoCD UI after pushing to a branch.
- Keep the template minimal; push app‑specific knobs into values/overlays.

