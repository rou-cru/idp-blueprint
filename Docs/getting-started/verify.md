# Verify Installation

After deploying the platform, validate core services and access endpoints.

## Quick Checks

Use these commands to confirm that control-plane and platform components are healthy:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -n argocd
```

## Access Endpoints

- ArgoCD: https://argocd.127-0-0-1.sslip.io
- Grafana: https://grafana.127-0-0-1.sslip.io
- Vault: https://vault.127-0-0-1.sslip.io
- Argo Workflows: https://workflows.127-0-0-1.sslip.io
- SonarQube: https://sonarqube.127-0-0-1.sslip.io

!!! tip
    Certificates are issued automatically by cert-manager using a wildcard
    certificate for `*.127-0-0-1.sslip.io`.

## Smoke Tests

- ArgoCD Applications show `Healthy/Synced` state
- Grafana loads and lists Prometheus and Loki data sources
- Trivy Operator reports appear under `vulnerabilityreports.aquasecurity.github.io`
- External Secrets creates Kubernetes Secrets for configured `ExternalSecret` resources

## Next

- Continue to [First Steps](first-steps.md)
- Or explore [Components](../components/infrastructure/index.md)

