# Code Style and Conventions

## YAML Files

- **Formatter**: Prettier (printWidth: 88, singleQuote: true)
- **Linter**: yamllint
- Line length handled by Prettier
- No document-start (---) required
- Any quote type allowed

## Markdown Files

- **Linter**: markdownlint-cli2
- Prose wrapped to print width (88 chars)

## Shell Scripts

- **Linter**: shellcheck
- Location: `Scripts/` directory

## Dockerfiles

- **Linter**: hadolint

## Kubernetes Manifests

### Resource Definitions (MANDATORY)

All workloads MUST define both `requests` and `limits` for CPU and memory:

```yaml
resources:
  requests:
    cpu: 100m      # Use millicores
    memory: 256Mi  # Use Mi or Gi
  limits:
    cpu: 1000m
    memory: 1Gi
```

**Exception**: cilium-agent DaemonSet (no limits for stability)

### Label Standards (Enforced by Kyverno)

Canonical values:

- `owner: platform-team`
- `business-unit: infrastructure`
- `environment: demo`
- `app.kubernetes.io/part-of: idp`

All namespaces MUST include: `app.kubernetes.io/part-of`, `owner`, `business-unit`, `environment`

## Helm Charts

### Values Documentation (helm-docs syntax)

```yaml
## @section Section Name
## @description Section description

# -- Parameter description
# @default -- default_value
parameterName: value
```

## Commit Standards

- **Format**: Conventional Commits (enforced by commitlint-rs)
- **Philosophy**: Atomic commits - one logical change per commit
- Enables effective `git bisect` for bug finding
- Easier code reviews and safer reverts

## Architecture Conventions

- `IT/` - Bootstrap/static infrastructure (Helm)
- `K8s/` - GitOps-managed applications (ArgoCD)
- `Policies/` - Policy-as-Code (Kyverno)
- `Task/` - Task runner configurations
- `Scripts/` - Automation scripts
- `Docs/` - MkDocs documentation
