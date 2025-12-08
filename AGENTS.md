# IDP Blueprint - AI Agent Reference Guide

## Project Overview

IDP Blueprint is a comprehensive open-source Internal Developer Platform reference
implementation designed for local or lab Kubernetes clusters (k3d by default). It
provides a complete GitOps-based platform with integrated tools for policy governance,
observability, CI/CD, and secrets management.

**Key Characteristics:**

- Production-ready enterprise platform architecture
- One-command deployment with full automation
- Modular component design with feature toggles
- GitOps-first approach using ArgoCD ApplicationSets
- Comprehensive developer experience with Backstage portal
- Policy-driven governance with Kyverno
- Security-first design with multiple scanning layers

## How to work

- **Serena**: If Serena MCP is available, then it's the main tool for all code-base
  work including investigation and exploring. Always.
- **Playwright**: If Playwright MCP is available, ask the user if a visual check or
  browser debug is needed after changes related to Backstage or Astro Documentation.
- **Sequential Thinking**: If sequential-thinking MCP is available, use it to argue
  against your first plan for huge or critical changes. Everything is wrong until
  you can demonstrate with objective evidence that your plan is correct and robust;
  only then ask the user for approval.
- **Planning**: Don't patch symptoms—find root causes and plan the fix before editing
  files.
- **User Plan requested**: If the user asks explicitly for a planning task for a
  refactor or a complex fix, after completing the planning read
  .serena/memories/validate_plan.md and do the validations.
- **Commits**: If Code Rabbit is available always run "cr --prompt-only" after stashed
  the changes and before complete the commit. Fix all the issues reported by Code
  Rabbit.

## Technology Stack

### Core Infrastructure

- **Container Orchestration**: Kubernetes (k3d for local development)
- **GitOps Engine**: ArgoCD with ApplicationSets (app-of-appsets pattern)
- **Container Network**: Cilium CNI with Gateway API
- **Package Management**: Devbox for toolchain management
- **Task Runner**: Task (go-task) for automation
- **Documentation**: Astro + Svelte 5 + Tailwind for documentation site

### Platform Components

1. **Policy & Governance**: Kyverno + Policy Reporter
2. **Networking**: Cilium CNI, Gateway API with wildcard TLS (nip.io)
3. **Secrets Management**: Vault + External Secrets Operator
4. **Observability**: Prometheus Operator CRDs, Grafana, Loki, Fluent Bit, Pyrra
5. **CI/CD**: Argo Workflows, SonarQube
6. **Developer Portal**: Backstage (React-based)
7. **Certificate Management**: cert-manager

## Repository Structure

```text
/home/rc/idp-blueprint/
├── IT/        # Bootstrap layer (Cilium, cert-manager, Vault, ESO, ArgoCD)
├── K8s/       # GitOps stacks (backstage, cicd, events, observability, security)
├── Policies/              # Kyverno engine and policies
├── Task/                  # Taskfile orchestration modules
├── Scripts/               # Helper scripts for config, vault, validation, documentation
├── UI/                    # Backstage developer portal (React/TypeScript with Yarn workspaces)
├── Catalog/               # Backstage service catalog YAML descriptors
└── Docs/                  # Astro documentation site
```

## Build and Test Commands

### Primary Deployment

```bash
# Full platform deployment
task deploy

# Individual component deployment
task bootstrap   # Infrastructure layer
task stacks      # Application stacks
task policies    # Kyverno policies
```

### Quality Checks

```bash
# Run all quality checks
task quality

# Individual checks
task lint-yaml
task lint-shell
task lint-dockerfile
task lint-markdown
task validate-k8s
task validate-consistency
```

### Development Environment

```bash
# Setup development environment
devbox shell

# Generate configuration
./Scripts/generate-env.sh

# Local cluster management
task k3d:create
task k3d:delete
```

### Documentation

```bash
# Build documentation
task docs:build

# Serve documentation locally
task docs:serve

# Validate documentation links
task docs:linkcheck
```

## Code Style Guidelines

### Prettier Configuration

- **Line Length**: 88 characters
- **Quote Style**: Single quotes
- **Markdown**: Prose wrap enabled

### YAML Standards (yamllint)

- Extends default configuration
- Line length handled by Prettier
- Document-start and comments disabled
- Relaxed braces, brackets, quoted-strings

### Markdown Standards (markdownlint)

- Line length: 92 characters
- Unordered lists use dashes
- Specific HTML elements allowed: `<details>`, `<summary>`, `<img>`

### Shell Script Standards

- All `.sh` files must pass shellcheck
- Follow POSIX compliance where possible
- Include proper error handling

### Resource Requirements

- All workloads must specify CPU/memory requests and limits
- Use appropriate units (m for CPU, Mi/Gi for memory)
- Cilium components are exempt from resource requirements

## Testing Instructions

### Infrastructure Validation

```bash
# Validate Kustomize builds
task validate-kustomize

# Validate Kubernetes manifests
task validate-k8s

# Validate Helm documentation
task lint-helm-docs
```

### Consistency Validation

- Labels must follow canonical standards
- PriorityClasses required on all workloads
- ArgoCD sync waves properly configured
- Resource requirements enforced

### Security Scanning

```bash
# Infrastructure as Code scanning
task security:iac

# Secret scanning
task security:secrets
```

## Security Considerations

### Policy Enforcement

- Kyverno policies enforce organizational standards
- Automatic label propagation required
- Namespace governance with required labels
- Business label auditing and enforcement

### Secret Management

- Vault used for secret storage
- External Secrets Operator for Kubernetes integration
- No hardcoded secrets in manifests
- Regular secret scanning in CI pipeline

### Container Security

- Multi-variant images (full, minimal, ops)
- Security scanning in CI pipeline
- Checkov for infrastructure security validation
- Trufflehog for secret detection

### Access Control

- ArgoCD projects for domain isolation
- RBAC policies in Backstage
- Service accounts with minimal permissions
- Network policies for traffic control

## Development Conventions

### Git Workflow

- All changes via pull requests
- Atomic commits for bisect-friendly history
- Commit message linting with commitlint-rs
- Stale issue management automation

### Label Standards

Required labels across all resources:

- `owner`: Team or individual responsible
- `business-unit`: Business unit ownership
- `environment`: Environment designation
- `app.kubernetes.io/part-of`: Application grouping

### ArgoCD Conventions

- ApplicationSets for bulk deployments
- AppProjects for domain isolation
- Sync waves for deployment order
- Health checks and sync policies

### Documentation Standards

- Auto-generated Helm documentation
- Component-specific architecture docs
- Conceptual documentation for design decisions
- Link validation for documentation integrity

## Feature Toggles

Configuration in `config.toml`:

- `enable_policies`: Kyverno policy enforcement
- `enable_observability`: Monitoring stack
- `enable_cicd`: CI/CD components
- `enable_security`: Security scanning
- `enable_backstage`: Developer portal

## Common Development Tasks

### Adding New Components

1. Create Kustomize base in appropriate directory
2. Add ArgoCD ApplicationSet configuration
3. Update feature toggle in config.toml
4. Add documentation and catalog entries
5. Include in Task orchestration

### Updating Dependencies

- Dependabot manages automated updates
- Grouped updates for related packages
- Security updates prioritized
- Review required for breaking changes

### Debugging Deployments

- Check ArgoCD sync status and logs
- Validate Kubernetes events
- Review policy reports for violations
- Check resource quotas and limits

This guide provides comprehensive information for AI agents working with the IDP
Blueprint project. Always refer to the actual configuration files and documentation for
the most current information.
