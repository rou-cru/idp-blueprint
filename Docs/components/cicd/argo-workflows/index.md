# argo-workflows

![Version: 0.45.27](https://img.shields.io/badge/Version-0.45.27-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://argoproj.github.io/workflows)

Kubernetes-native workflow engine for orchestrating parallel jobs

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.45.27` |
| **Chart Type** | `application` |
| **Upstream Project** | [argo-workflows](https://argoproj.github.io/workflows) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Argo Workflows?

Argo Workflows is a Kubernetes-native workflow engine that uses DAGs (Directed Acyclic Graphs) to orchestrate parallel jobs. It handles CI/CD pipelines, data processing, and any workflow that requires sequencing and parallelization.

The DAG model is powerful. You define steps and their dependencies, Argo executes them in the correct order, handles failures, and manages artifact passing between steps. The workflow is a Kubernetes resource, so it integrates with the GitOps approach.

Argo Workflows works alongside ArgoCD and Argo Events as part of the Argo ecosystem. Workflows can be triggered by events, process artifacts, update Git repositories, and trigger ArgoCD syncs.

## Architecture Role

Argo Workflows operates at **Layer 2** of the platform, the Automation & Governance layer.

Key integration points:

- **Argo Events**: Triggers workflows based on events (Git push, webhooks, schedules)
- **Container Registry**: Workflows build and push container images
- **Git Provider**: Workflows can commit manifest updates
- **Prometheus**: Exposes metrics on workflow execution

Workflows run as Pods, so they consume cluster resources during execution. The configuration uses artifact repositories for passing data between workflow steps.

See [CI/CD Model](../../../architecture/cicd.md) for how workflows integrate into the platform.

## Configuration Values

--8<-- "_values.generated.md"
