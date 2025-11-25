---
title: Helm Docs Conventions
sidebar:
  label: Helm Docs Conventions
  order: 10
---
---


Document values where they live. `helm-docs` turns comments into tables users can trust.

## Comment style

- `# @section -- <Group>` to group values
- `# -- <description>` for each value
- `# @default -- <value>` to capture defaults (when helpful)

## Workflow

- Update comments as you change values files.
- Lint docs before PRs (`Scripts/helm-docs-lint.sh`) if configured.
