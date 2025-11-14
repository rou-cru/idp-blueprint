
---
# Getting Started — Read this before you run anything

Welcome. You’re about to stand up an IDP you can understand and change. Keep this mental model in mind while you follow the steps.

## The mental model

```d2
direction: right

Desired: {
  label: "Desired State (Git)"
}

Actionable: {
  label: "Actionable State"
  GitOps: "ArgoCD"
  Policy: "Kyverno"
}

Observed: {
  label: "Observed State"
  Metrics: "Prometheus"
  Logs: "Loki"
}

Desired -> Actionable.GitOps: reconcile
Desired -> Actionable.Policy: govern
Actionable.GitOps -> Observed.Metrics: deploy → measure
```

You’ll see these loops in action during deploy and verification.

## What you'll build

```d2
direction: right

You: {
  label: "You"
  shape: person
}

External: {
  label: "External"
  Repo: {
    label: "GitHub Repository"
    shape: cloud
  }
  Docker: {
    label: "Docker Hub"
    shape: cloud
  }
}

Local: {
  label: "Local Environment"
  Dev: "Dev Container / Tooling"
}

Cluster: {
  label: "Local IDP Cluster (k3d)"
  Gateway: {
    label: "Gateway (nip.io + TLS)"
    shape: cloud
  }
  UIs: {
    label: "Platform UIs"
    ArgoCD: "ArgoCD"
    Grafana: "Grafana"
    Vault: "Vault"
  }
}

You -> External.Repo: clone
You -> Local.Dev: run tasks
Local.Dev -> External.Docker: pull images
You -> Cluster.Gateway: open URLs
Cluster.Gateway -> Cluster.UIs.ArgoCD
Cluster.Gateway -> Cluster.UIs.Grafana
Cluster.Gateway -> Cluster.UIs.Vault
```

## What you'll learn

In this getting started section, you'll learn:

- **Prerequisites**: What tools and resources you need before starting
- **Quick Start**: How to deploy the platform with a single command
- **Deployment Process**: Understanding what happens during the deployment

## Next steps

Start with the [Prerequisites](prerequisites.md) to ensure your environment is ready,
then move on to the [Quick Start](quickstart.md) guide to deploy your first IDP instance.
