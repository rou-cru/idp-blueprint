# Backstage Component to Kubernetes Resource Mapping for Kyverno Annotations

This document maps each Backstage component to its corresponding Kubernetes resource for Kyverno Policy Reporter integration.

## Components with Kyverno Annotations (Already configured)
- `backstage`: Deployment/backstage in namespace backstage
- `dex`: Deployment/dex in namespace backstage

## Components Requiring Kyverno Annotations

### Cert-Manager (cert-manager namespace)
- `cert-manager`: Deployment/cert-manager

### Argo Events (argo-events namespace)
- `argo-events`: Deployment/argo-events-controller-manager (matches kubernetes-id pattern)
- `argo-events-controller-manager`: Deployment/argo-events-controller-manager
- `eventbus`: StatefulSet/eventbus-default-stan

### Observability (observability namespace)
- `grafana`: Deployment/prometheus-grafana
- `kube-state-metrics`: Deployment/prometheus-kube-state-metrics
- `node-exporter`: DaemonSet/prometheus-prometheus-node-exporter
- `pyrra`: Deployment/pyrra
- `fluent-bit`: DaemonSet/fluent-bit
- `kube-prometheus-stack`: Deployment/prometheus-kube-prometheus-operator
- `alertmanager`: NOT FOUND in cluster (component exists but no matching resource)
- `loki`: NOT FOUND in cluster (component exists but no matching resource)

### CICD (cicd namespace)
- `argo-workflows`: Deployment/argo-workflows-server (main server component)
- `argo-server`: Deployment/argo-workflows-server
- `workflow-controller`: Deployment/argo-workflows-workflow-controller
- `sonarqube`: StatefulSet/sonarqube-sonarqube

### Kube-System (kube-system namespace)
- `cilium-operator`: Deployment/cilium-operator
- `cilium-agent`: DaemonSet/cilium
- `hubble-ui`: Deployment/hubble-ui
- `hubble-relay`: Deployment/hubble-relay
- `idp-gateway`: DaemonSet/cilium-envoy (gateway uses Cilium Envoy)

### ArgoCD (argocd namespace)
- `argocd-server`: Deployment/argocd-server
- `argocd-repo-server`: Deployment/argocd-repo-server
- `argocd-application-controller`: StatefulSet/argocd-application-controller
- `argocd`: Deployment/argocd-server (main component)

### Kyverno System (kyverno-system namespace)
- `kyverno`: Deployment/kyverno-admission-controller (main controller)
- `policy-reporter`: Deployment/policy-reporter

### External Secrets (external-secrets-system namespace)
- `external-secrets`: Deployment/external-secrets

### Vault (vault namespace)
- `vault`: NOT FOUND in cluster (namespace exists but empty)

### Components Without Clear K8s Resources
- `cilium`: This is a parent component; actual resources are cilium-agent and cilium-operator
- `trivy-operator`: NOT FOUND in cluster search
- `idp-docs`: Likely a documentation component, not a K8s resource

## Notes
- Some components reference chart-level resources rather than specific workloads
- Loki, Alertmanager, and Vault are catalog entries but don't have active deployments
- Some components need clarification on which specific resource to track
