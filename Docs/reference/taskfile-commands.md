# Taskfile Commands

Frequently used automation tasks.

## Core

- `task deploy` – Provision the full platform
- `task destroy` – Tear down the demo cluster

## Stacks

- `task stacks:deploy` – Redeploy ApplicationSet layer(s)
- `task policies:deploy` – Redeploy policy layer(s)

## Quality

- `task check` – Run linters, schema validation and security scans
- `task lint` / `task validate:kubeval` – Targeted checks

