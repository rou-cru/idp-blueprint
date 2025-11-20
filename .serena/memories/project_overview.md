# IDP Blueprint - Project Overview

## Purpose

An **Internal Developer Platform (IDP) Blueprint** - a complete platform engineering stack
(GitOps, Observability, Security & Policy Enforcement) that can be deployed with a single
command on a local machine using K3d.

## Target Audience

- Platform Engineers: Prototype and validate infrastructure changes
- DevOps/SRE Teams: Learning lab for cloud-native tools
- Security Engineers: Validate compliance controls

## Tech Stack

### Core Infrastructure (IT/)

- **Cilium** - eBPF-based CNI, network policies, LoadBalancer
- **Cert-Manager** - TLS certificate automation
- **Vault** - Secret storage backend
- **External Secrets** - Vault-to-Kubernetes secret sync
- **ArgoCD** - GitOps engine

### Policy Layer (Policies/)

- **Kyverno** - Policy enforcement engine
- **Policy Reporter** - Compliance monitoring dashboard

### Application Stacks (K8s/)

- **Observability**: Prometheus, Grafana, Loki, Fluent-bit
- **CI/CD**: Argo Workflows, SonarQube
- **Security**: Trivy Operator

## Development Tools

- **Task** - Task runner (Taskfile.yaml)
- **Devbox** - Development environment management
- **VS Code Dev Containers** - Containerized dev environment
- **MkDocs** - Documentation site

## Programming Languages

- Bash scripts (automation)
- YAML/TOML (configuration)
- Markdown (documentation)
- Python 3.12 (MkDocs tooling)

## Resource Requirements

- Minimum: 4 CPU cores, 8GB RAM
- Comfortable: 6 CPU cores, 12GB RAM
- Disk: ~20GB available

## Architecture

- 3-node K3d cluster: Control Plane, Static Infrastructure, GitOps Workloads
- GitOps-first approach with ArgoCD
- Policy-as-Code with Kyverno
- Vault as source of truth for secrets
