#!/bin/bash
# Generate Chart.yaml files for all components based on Taskfile versions
# This creates semantic .gitkeep files that helm-docs can use for metadata

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Component metadata mapping
# Format: "component_name|category|description|homepage|source_path|version_var"
COMPONENTS=(
  # Infrastructure
  "cilium|infrastructure|eBPF-based CNI with Gateway API support and L7 proxy capabilities|https://cilium.io|IT/cilium/cilium-values.yaml|CILIUM_VERSION"
  "argocd|infrastructure|Declarative GitOps continuous delivery for Kubernetes|https://argo-cd.readthedocs.io|IT/argocd/argocd-values.yaml|ARGOCD_VERSION"
  "vault|infrastructure|Secrets management and data protection platform|https://www.vaultproject.io|IT/vault/vault-values.yaml|VAULT_VERSION"
  "cert-manager|infrastructure|Cloud-native certificate management for Kubernetes|https://cert-manager.io|IT/cert-manager/cert-manager-values.yaml|CERT_MANAGER_VERSION"
  "external-secrets|infrastructure|Synchronize secrets from external sources into Kubernetes|https://external-secrets.io|IT/external-secrets/eso-values.yaml|EXTERNAL_SECRETS_VERSION"

  # Policy
  "kyverno|policy|Kubernetes-native policy management and security engine|https://kyverno.io|Policies/kyverno/kyverno-values.yaml|"
  "policy-reporter|policy|Monitoring and observability for policy engine results|https://kyverno.github.io/policy-reporter|Policies/policy-reporter/policy-reporter-values.yaml|"

  # Observability
  "prometheus|observability|Prometheus monitoring stack with Grafana and Alertmanager|https://prometheus.io|K8s/observability/kube-prometheus-stack/kube-prometheus-stack-values.yaml|"
  "loki|observability|Log aggregation system designed to store and query logs|https://grafana.com/oss/loki|K8s/observability/loki/loki-values.yaml|"
  "fluent-bit|observability|Fast and lightweight log processor and forwarder|https://fluentbit.io|K8s/observability/fluent-bit/fluent-bit-values.yaml|"

  # CI/CD
  "argo-workflows|cicd|Kubernetes-native workflow engine for orchestrating parallel jobs|https://argoproj.github.io/workflows|K8s/cicd/argo-workflows/argo-workflows-values.yaml|"
  "sonarqube|cicd|Code quality and security analysis platform|https://www.sonarsource.com/products/sonarqube|K8s/cicd/sonarqube/sonarqube-values.yaml|"

  # Security
  "trivy|security|Comprehensive security scanner for vulnerabilities and misconfigurations|https://trivy.dev|K8s/security/trivy/trivy-values.yaml|"
)

# Get version from Taskfile or use default
get_version() {
  local version_var=$1

  if [ -z "$version_var" ]; then
    echo "latest"
    return
  fi

  # Extract version from Taskfile using grep and awk
  local version=$(grep -E "^\s+${version_var}:" Taskfile.yaml | awk -F'"' '{print $2}')

  if [ -z "$version" ]; then
    echo "latest"
  else
    echo "$version"
  fi
}

# Generate Chart.yaml for a component
generate_chart_yaml() {
  local component=$1
  local category=$2
  local description=$3
  local homepage=$4
  local source_path=$5
  local version_var=$6

  local version=$(get_version "$version_var")
  local output_dir="docs/components/${category}/${component}"
  local output_file="${output_dir}/Chart.yaml"

  mkdir -p "$output_dir"

  cat > "$output_file" <<EOF
apiVersion: v2
name: ${component}
version: ${version}
description: ${description}
type: application
home: ${homepage}
sources:
  - https://github.com/rou-cru/idp-blueprint
maintainers:
  - name: Platform Engineering Team
    url: https://github.com/rou-cru/idp-blueprint
annotations:
  idp.blueprint/category: ${category}
  idp.blueprint/source: ${source_path}
  idp.blueprint/managed-by: helm-docs
EOF

  echo "✅ Generated: $output_file (version: $version)"
}

# Main execution
echo "🔧 Generating Chart.yaml files for all components..."
echo ""

for component_spec in "${COMPONENTS[@]}"; do
  IFS='|' read -r name category description homepage source version_var <<< "$component_spec"
  generate_chart_yaml "$name" "$category" "$description" "$homepage" "$source" "$version_var"
done

echo ""
echo "✅ All Chart.yaml files generated successfully!"
echo "📝 These files serve as semantic .gitkeep and provide metadata for helm-docs"
