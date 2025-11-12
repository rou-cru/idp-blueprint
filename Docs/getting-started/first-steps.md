# First Steps

This guide highlights what to do right after a successful installation.

## 1) Explore GitOps state

- Open ArgoCD and review Applications and ApplicationSets
- Identify how each stack (observability, security, policy, CI/CD) is wired

## 2) Check policy enforcement

- Inspect Kyverno policies and violations via Policy Reporter
- Try applying a non-compliant manifest and observe the response

## 3) Review observability

- Access Grafana and open prebuilt dashboards (Kubernetes / Nodes / Pods)
- Verify Prometheus targets and Loki log streams

## 4) Validate secrets flow

- Confirm External Secrets pulls a value from Vault into a Kubernetes Secret
- Inspect the rendered Secret and ensure your workloads can mount it

## 5) Try a tutorial

- [Onboard an Application](../tutorials/onboard-app.md)
- [Add a Policy (Kyverno)](../tutorials/add-policy.md)
- [Consume a Secret from Vault](../tutorials/consume-secret.md)
- [Add an Observability Dashboard](../tutorials/add-dashboard.md)

