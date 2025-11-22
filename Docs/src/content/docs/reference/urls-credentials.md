---
title: URLs & Initial Credentials
sidebar:
  label: URLs & Credentials
  order: 2
---

Where to access services and how to log in the first time.

## URLs

See [Ports & Endpoints](ports-endpoints.md) for the full list.

## Initial Credentials

:::note
This section will document default or bootstrap credentials for local/demo
environments only. Production guidance should use external SSO/secret stores.
:::

- ArgoCD: admin password via `argocd-initial-admin-secret` or configured value
- Grafana: bootstrap admin password from values or secret
- Vault: unseal keys and root token via `task vault:init` (local only)
