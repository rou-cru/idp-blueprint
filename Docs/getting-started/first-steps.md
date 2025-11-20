# First Steps — What to explore right away

This guide highlights what to do right after a successful installation.

## Explore GitOps state

- Open ArgoCD and review Applications and ApplicationSets (ApplicationSets
  generate many Applications from the `K8s/` folder structure; see
  [`GitOps, Policy, and Eventing`](../concepts/gitops-model.md))
- Identify how each stack (observability, security, policy, CI/CD) is wired

## Check policy enforcement

- Inspect Kyverno policies and violations via Policy Reporter
- Try applying a non-compliant manifest and observe the response

## Review observability

- Access Grafana and open prebuilt dashboards (Kubernetes / Nodes / Pods)
- Verify Prometheus targets and Loki log streams

## Validate secrets flow

- Confirm External Secrets pulls a value from Vault into a Kubernetes Secret
- Inspect the rendered Secret and ensure your workloads can mount it
