# Codebase Structure

## Root Directory

```
idp-blueprint/
├── config.toml          # Main configuration (versions, passwords, network)
├── Taskfile.yaml        # Main task runner entry point
├── devbox.json          # Development environment packages
├── pyproject.toml       # Python dependencies (MkDocs)
├── mkdocs.yml           # MkDocs configuration
├── docker-bake.hcl      # Docker build configuration
└── README.md            # Project documentation
```

## Main Directories

### IT/ - Static Infrastructure (Bootstrap Layer)

Deployed via Helm during bootstrap phase:

- Cilium CNI
- Cert-Manager
- Vault
- External Secrets
- ArgoCD

### K8s/ - GitOps Applications

Managed by ArgoCD ApplicationSets:

- Observability stack (Prometheus, Grafana, Loki, Fluent-bit)
- CI/CD stack (Argo Workflows, SonarQube)
- Security stack (Trivy)

### Policies/ - Policy-as-Code

Kyverno policies and Policy Reporter:

- Namespace label enforcement
- Best practices validation

### Task/ - Task Runner Configurations

```
Task/
├── bootstrap.yaml    # Bootstrap tasks
├── k3d.yaml         # K3d cluster management
├── stacks.yaml      # Application stack deployment
├── quality.yaml     # Lint, validate, security tasks
├── image.yaml       # Docker image tasks
└── utils.yaml       # Utility tasks
```

### Scripts/ - Automation Scripts

```
Scripts/
├── vault-init.sh           # Vault initialization
├── vault-generate.sh       # Vault secret generation
├── helm-docs-*.sh          # Helm documentation scripts
├── validate-consistency.sh # Consistency validation
└── docs-linkcheck.sh       # Documentation link checker
```

### Docs/ - Documentation

MkDocs site with:

- `architecture/` - System architecture docs
- `guides/` - How-to guides
- `reference/` - Standards and references
- `getting-started/` - Quick start guides

### Configuration Files

- `.yamllint` - YAML linter config
- `.prettierrc.yaml` - Prettier formatter config
- `.markdownlint-cli2.yaml` - Markdown linter config
- `.trufflehog-ignore` - Secret scanner exclusions

### Development Environment

- `.devcontainer/` - VS Code Dev Container config
- `.devbox/` - Devbox cache (gitignored)
- `.venv/` - Python virtual environment
