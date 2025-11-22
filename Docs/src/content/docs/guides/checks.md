---
title: Checks & Linting
sidebar:
  label: Checks
  order: 4
---

How to run validations locally before pushing changes.

## All-in-one

- `task check` – run all linters, schema validation and security scans

## Targeted

- `task lint:yaml` – YAML linting
- `task validate:kustomize` – Build overlays
- `./Scripts/helm-docs-lint.sh` – Validate Helm docs comments
- `./Scripts/validate-consistency.sh` – Canonical labels and priority classes
