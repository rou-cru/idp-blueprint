# Logs JSON enablement exclusions (Dec 24, 2025)

## Excluded components and reasons

- Backstage (K8s/backstage/backstage/values.yaml)
  - Status: No Helm values toggle for JSON output; requires code change to override root logger.
  - Reason excluded: requires application code change (out of scope).