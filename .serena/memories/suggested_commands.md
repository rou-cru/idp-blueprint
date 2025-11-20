# Suggested Commands

## Main Deployment Commands

```bash
task deploy                  # Deploy the entire IDP platform (~5-10 min)
task deploy KUBECTL_TIMEOUT=600s  # Deploy with extended timeout
task destroy                 # Remove all components and cluster
task redeploy               # Destroy and deploy from scratch
task deploy:nocache         # Deploy without registry cache
```

## Quality Checks (Run before PRs)

```bash
task check                  # Run ALL checks (lint, validation, security)
task lint                   # Run all linters
task lint:yaml              # Lint YAML files only
task lint:shell             # Lint shell scripts only
task lint:dockerfile        # Lint Dockerfiles only
task lint:markdown          # Lint Markdown files only
task lint:helm              # Validate Helm values documentation
task lint:commit            # Lint the last commit message
```

## Validation

```bash
task validate               # Run all validation tasks
task validate:kustomize     # Validate all Kustomize overlays
task validate:kubeval       # Validate K8s manifests + schemas
```

## Security Scanning

```bash
task security               # Run all security scanners
task security:iac           # Scan IaC for misconfigurations (checkov)
task security:secrets       # Scan for hardcoded secrets (trufflehog)
```

## Documentation

```bash
task utils:docs:all                # Generate markdown from helm-docs, build MKDocs and Lint
```

## Utility Commands

```bash
task cleanup                # Remove temporary chart directories
```

## Kubernetes Tools (from devbox)

- `kubectl` - Kubernetes CLI
- `k9s` - Terminal UI for K8s
- `helm` - Package manager for K8s
- `kustomize` - K8s configuration customization
- `argocd` - ArgoCD CLI
- `cilium` - Cilium CLI
- `vault` - Vault CLI

## System Utilities (Linux)

- `git`, `ls`, `cd`, `grep`, `find`
- `jq`, `yq`, `dasel` - JSON/YAML/TOML processors
