---
# Getting started — read this before you run anything

Welcome. In this section you will deploy the platform locally, check that it is healthy, and understand at a high level what you just created.

If you want the full architectural view, see [Architecture overview](../architecture/overview.md). Here we focus on what you need to know to run the commands with confidence.

## What you will build

After completing the quickstart you will have:

- A local k3d Kubernetes cluster (by default `idp-demo`).
- Core platform services:
  - Cilium, Gateway API.
  - Vault, External Secrets Operator, cert‑manager.
  - Prometheus, Loki, Grafana.
- GitOps and policy control planes:
  - ArgoCD with ApplicationSets (a controller that generates many Applications
    from the `K8s/` folder structure; see
    [`GitOps, Policy, and Eventing`](../concepts/gitops-model.md)).
  - Kyverno and Policy Reporter.
- Stacks for:
  - Observability.
  - CI/CD.
  - Security scanning.

All of this is deployed from this repository using `task deploy`.

## What you will learn

In this getting started section you will:

- Check **prerequisites** for your local machine.
- Run the **quickstart** to deploy the platform.
- Understand at a high level what happens during deployment.
- Verify that key components are healthy.

## Reading order

Recommended order:

1. [Prerequisites](prerequisites.md) — tools and baseline resources.
2. [Quickstart](quickstart.md) — one command to deploy.
3. [Verify installation](verify.md) — basic checks and expected results.
4. [First steps](first-steps.md) — guided exploration of the UIs and GitOps flows.

Once you are comfortable with the running cluster, read [Architecture overview](../architecture/overview.md) and [Concepts](../concepts/index.md) to understand the platform design in depth.
