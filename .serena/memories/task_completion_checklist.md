# Task Completion Checklist

## Before Submitting Changes

### 1. Run Quality Checks

```bash
task check    # Runs: lint + validate + security
```

Or run individual checks:

```bash
task lint                 # All linters
task validate:kubeval     # K8s manifest validation
task security             # Security scans
```

### 2. Validate Specific Changes

**For YAML changes:**

```bash
task lint:yaml
```

**For Shell scripts:**

```bash
task lint:shell
```

**For Markdown:**

```bash
task lint:markdown
```

**For Helm charts:**

```bash
task lint:helm
```

**For Kustomize overlays:**

```bash
kustomize build <directory> --enable-helm
```

### 3. Security Verification

```bash
task security:iac         # Check for misconfigurations
task security:secrets     # Check for hardcoded secrets
```

### 4. Commit Hygiene

- Use atomic commits (one logical change per commit)
- Follow Conventional Commits format
- Never add a Sign to the commits if not ask for it explicetly
- Verify commit message: `task lint:commit`

### 5. Label Compliance

Ensure Kubernetes resources have required labels:

- `app.kubernetes.io/part-of`
- `owner`
- `business-unit`
- `environment`

### 6. Resource Definitions

Verify all workloads have `requests` and `limits` with explicit units (millicores for CPU,
Mi/Gi for memory)

### 7. Documentation

- Update helm-docs comments in values.yaml if needed
- Run `task utils:docs:helm` to regenerate doc files from helm-docs comments

## Reference Documentation

- `Docs/guides/contributing.md` - Full contribution guidelines
- `Docs/reference/labels-standard.md` - Label standards
- `.memory/graph.db` - Graph representation of the proyect as
  multidimensional map(Memory MCP Server for manipulation)
