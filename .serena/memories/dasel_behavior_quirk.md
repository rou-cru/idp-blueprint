# Dasel Behavior Quirk - Single Quote Wrapping

## Issue Discovered
Date: 2025-11-19

## Problem
When reading TOML values, `dasel` returns string values wrapped in single quotes.

Example:
```toml
# config.toml
grafana_admin = "graf"
argocd_admin = "argo"
```

```bash
$ dasel -r toml -f config.toml passwords.grafana_admin
'graf'   # Note the single quotes!

$ dasel -r toml -f config.toml passwords.argocd_admin
'argo'
```

## Impact
Any command using `tr -d '"'` to strip quotes will fail because it only removes double quotes, not single quotes.

**Broken pattern:**
```bash
dasel -r toml -f config.toml some.key | tr -d '"'
# Returns: 'value' (single quotes remain)
```

**Correct pattern:**
```bash
dasel -r toml -f config.toml some.key | tr -d "'\""
# Returns: value (both quote types removed)
```

## Files Affected
- Task/bootstrap.yaml - Multiple variable definitions
- Taskfile.yaml - Multiple variable definitions
- Any other files using dasel with `tr -d '"'`

## Root Cause
This caused authentication failures in ArgoCD and Grafana because:
- ArgoCD bcrypt hash was generated for `'argo'` instead of `argo`
- Grafana password was stored as `'graf'` instead of `graf`
