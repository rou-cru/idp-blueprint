#!/bin/bash

# Load vars from Env file if exist
if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi


# Add Bcrypt
go install github.com/shoenig/bcrypt-tool@latest

# -- CNI
helm repo add cilium https://helm.cilium.io/
# -- GitOps & Event-Driven Automation
helm repo add argo https://argoproj.github.io/argo-helm
# -- Observability
prometheus-community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-prometheus-stack https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add fluent https://fluent.github.io/helm-charts
# -- Quality
helm repo add sonarsource https://SonarSource.github.io/helm-chart-sonarqube
# -- Security
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo add aqua https://aquasecurity.github.io/helm-charts/

# -- Sensitive Data 
helm repo add external-secrets https://charts.external-secrets.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add jetstack https://charts.jetstack.io/
# helm repo add falcosecurity https://falcosecurity.github.io/charts
# -- DevOps Advanced Tools
helm repo add pixie-operator https://artifacts.px.dev/helm_charts/operator 
helm repo add policy-reporter https://kyverno.github.io/policy-reporter
# helm repo add kubecost https://kubecost.github.io/cost-analyzer/
# -- CI/CD & IaC
helm repo add jenkins https://charts.jenkins.io
# helm repo add crossplane-stable https://charts.crossplane.io/stable
# -- Backup & Disaster
# helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts # Para Velero
# -- Just in Case
helm repo add bitnami https://charts.bitnami.com/bitnami
# -- Complete Helm setup
helm repo update