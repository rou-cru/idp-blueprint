# GitOps Model

This project adopts a GitOps-first approach using ArgoCD and ApplicationSets.

## App-of-Apps pattern

ArgoCD manages a parent Application that points to directories containing
ApplicationSets. Each `ApplicationSet` dynamically generates child Applications
based on generators (e.g., directory). This enables teams to add components by
just creating a new folder with a Kustomize overlay.

## Desired vs. actual state

ArgoCD continuously reconciles the cluster against the desired state stored in
Git. Any drift is detected and surfaced in the UI and can be auto-corrected.

## Policy and Secrets integration

- Kyverno validates and mutates resources at admission time
- External Secrets Operator syncs secrets from Vault into Kubernetes Secrets

For a visual overview, see [Visual Map](../architecture/visual.md) and
[Bootstrap Process](../architecture/bootstrap.md).

