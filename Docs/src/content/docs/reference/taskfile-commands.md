---
title: Task CLI Guide
sidebar:
  label: Task CLI
  order: 4
---

`task` is the primary entrypoint for bootstrap, quality gates, and docs automation. Treat it like any other CLI: list the commands, read inline help, then run the subcommand you need.

## Discover commands quickly

```bash
# Show the curated list of tasks
task --list

# Dump every task (namespaced + hidden)
task -a

# Show details for a specific task
task --summary stacks:events
```

Tasks inherit the `CONFIG_FILE` variable (defaults to `config.toml`). Override it per run:

```bash
CONFIG_FILE=config.prod.toml task deploy
```

## Go-to workflows

| Task | When to use |
|------|-------------|
| `task deploy` | End-to-end bootstrap (k3d, IT layer, Gateway, stacks). |
| `task destroy` | Tear everything down (k3d cluster + registry cache). |
| `task redeploy` | Convenience wrapper for `destroy` followed by `deploy`. |
| `task utils:config:print` | Inspect effective repo/branch, cluster name, LAN IP, NodePorts, and fuse values. |
| `task utils:ca:export` | Export the platform CA cert to trust the Gateway endpoints locally. |

## Stack management

All stacks are reconciled through ArgoCD ApplicationSets. Use these when iterating on a specific layer:

- `task stacks:deploy` — runs every stack respecting the fuses.
- `task stacks:policies` — Kyverno engine + policies (namespace guardrails, labels, quotas).
- `task stacks:observability` — Prometheus, Grafana, Loki, Fluent-bit, Pyrra.
- `task stacks:cicd` — Argo Workflows, SonarQube, CI helpers.
- `task stacks:security` — Trivy operator stack.
- `task stacks:events` — Argo Events controller/webhook + EventBus.

## Quality & security automation

The `quality` namespace exposes the same batteries that CI runs:

- `task quality:check` — umbrella for cleanup → lint → validate → security scans.
- `task quality:lint` — YAML, Shell, Dockerfile, Markdown, Helm docs (or target a specific lint task such as `quality:lint:helm`).
- `task quality:validate:kustomize` / `quality:validate:kubeval` — build every overlay and verify against schemas.
- `task quality:security` — checkov (IaC) + trufflehog (secrets); subcommands are available for focused runs.

## Documentation pipeline

Everything related to docs lives under `utils:docs:*`:

- `task utils:docs` — regenerate Chart metadata and helm-docs snippets.
- `task docs:build`: Build the documentation site (wraps `astro build`).
- `task utils:docs:serve` — live-reload server.
- `task utils:docs:linkcheck` — broken-link detector.
- `task utils:docs:all` — generate → build → linkcheck in one go.

## Images & registry helpers

- `task image:image:build` / `image:image:build:minimal` — build devcontainer images via `docker bake`.
- `task image:image:release` / `image:image:release:minimal` / `image:image:release:all` — build + push (requires registry credentials).
- `task image:registry:info` — show cache status, disk usage, and endpoint.
- `task image:registry:clean` — delete the local cache directory.

## Tips

- Namespaces map 1:1 with include files (`stacks:*`, `quality:*`, `utils:*`). Use shell completion or `task --list` whenever you forget the exact name.
- Most subtasks rely on `kubectl`, `helm`, `kustomize`, `envsubst`, or `uv`. Make sure those CLIs are installed before running the task.
- Every task supports `TASK_COLOR=false task …` if you need monochrome logs for CI.
