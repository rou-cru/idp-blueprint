# Completion Checklist

- Run quality gates relevant to your change:
  - Full gate: `task quality:check`
  - At minimum: `task quality:lint` (YAML, shell, Dockerfile, markdown, helm-docs) + `task quality:validate` (kustomize build + kubeval) for manifest edits.
  - Run `task quality:security:iac`/`task quality:security:secrets` when touching infra or secrets-sensitive areas.
- If modifying Helm values or charts, regenerate docs/metadata: `task utils:docs` (or `task utils:docs:helm`).
- If touching docs site, build or dev-serve to verify: `task docs:astro:build` or `task docs:astro:dev`.
- Check effective config if behavior depends on fuses/ports: `task utils:config:print`.
- Ensure commits are atomic and commit message lints pass (`task quality:lint:commit`).
- Update relevant documentation/README snippets when behavior changes.
