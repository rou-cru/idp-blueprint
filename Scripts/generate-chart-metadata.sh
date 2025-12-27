#!/usr/bin/env bash
# Generate Chart.yaml files for all components based on versions from:
# - kustomization.yaml (for GitOps components)
# - Taskfile.yaml (for infrastructure components)
# This creates semantic .gitkeep files that helm-docs can use for metadata

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Component metadata mapping
# Format: "component_name|category|description|homepage|source_path|version_var|helm_chart_name"
# helm_chart_name: name in kustomization.yaml (if different from component_name)
COMPONENTS=(
  # Infrastructure (versions from Taskfile.yaml)
  "cilium|infrastructure|eBPF-based CNI with Gateway API support and L7 proxy capabilities|https://cilium.io|IT/cilium/values.yaml|CILIUM_VERSION|"
  "argocd|infrastructure|Declarative GitOps continuous delivery for Kubernetes|https://argo-cd.readthedocs.io|IT/argocd/values.yaml|ARGOCD_VERSION|"
  "vault|infrastructure|Secrets management and data protection platform|https://www.vaultproject.io|IT/vault/values.yaml|VAULT_VERSION|"
  "cert-manager|infrastructure|Cloud-native certificate management for Kubernetes|https://cert-manager.io|IT/cert-manager/values.yaml|CERT_MANAGER_VERSION|"
  "external-secrets|infrastructure|Synchronize secrets from external sources into Kubernetes|https://external-secrets.io|IT/external-secrets/values.yaml|EXTERNAL_SECRETS_VERSION|"

  # Policy (versions from kustomization.yaml)
  "kyverno|policy|Kubernetes-native policy management and security engine|https://kyverno.io|Policies/kyverno/kyverno-values.yaml||kyverno"
  "policy-reporter|policy|Monitoring and observability for policy engine results|https://kyverno.github.io/policy-reporter|Policies/policy-reporter/policy-reporter-values.yaml||policy-reporter"

  # Observability (versions from kustomization.yaml)
  "prometheus|observability|Prometheus monitoring stack with Grafana and Alertmanager|https://prometheus.io|K8s/observability/kube-prometheus-stack/kube-prometheus-stack-values.yaml||kube-prometheus-stack"
  "loki|observability|Log aggregation system designed to store and query logs|https://grafana.com/oss/loki|K8s/observability/loki/loki-values.yaml||loki"
  "fluent-bit|observability|Fast and lightweight log processor and forwarder|https://fluentbit.io|K8s/observability/fluent-bit/fluent-bit-values.yaml||fluent-bit"

  # CI/CD (versions from kustomization.yaml)
  "argo-workflows|cicd|Kubernetes-native workflow engine for orchestrating parallel jobs|https://argoproj.github.io/workflows|K8s/cicd/argo-workflows/argo-workflows-values.yaml||argo-workflows"
  "sonarqube|cicd|Code quality and security analysis platform|https://www.sonarsource.com/products/sonarqube|K8s/cicd/sonarqube/sonarqube-values.yaml||sonarqube"

  # Security (versions from kustomization.yaml)
  "trivy|security|Comprehensive security scanner for vulnerabilities and misconfigurations|https://trivy.dev|K8s/security/trivy/trivy-values.yaml||trivy-operator"
)

# Get version from kustomization.yaml for GitOps components
get_version_from_kustomize() {
  local helm_chart_name=$1
  local source_dir=$2

  # Try kustomization.yaml in component directory
  local kustomize_file="$source_dir/kustomization.yaml"

  # If not found, try parent directory (e.g., Policies/kustomization.yaml)
  if [ ! -f "$kustomize_file" ]; then
    kustomize_file="$(dirname "$source_dir")/kustomization.yaml"
  fi

  # If still not found, try two levels up (some components might be nested)
  if [ ! -f "$kustomize_file" ]; then
    kustomize_file="$(dirname "$(dirname "$source_dir")")/kustomization.yaml"
  fi

  if [ ! -f "$kustomize_file" ]; then
    return 1
  fi

  # Parse version using yq (with jq syntax for python-yq)
  local version
  version=$(yq -r ".helmCharts[] | select(.name == \"$helm_chart_name\") | .version" "$kustomize_file" 2>/dev/null)

  if [ -n "$version" ] && [ "$version" != "null" ]; then
    echo "$version"
    return 0
  fi

  return 1
}

# Get version from config.toml for infrastructure components
get_version_from_config() {
  local version_var=$1

  if [ -z "$version_var" ]; then
    return 1
  fi

  # Convert version_var from UPPER_SNAKE_CASE to lowercase with underscores
  # CILIUM_VERSION -> cilium
  local config_key
  config_key=$(echo "$version_var" | sed 's/_VERSION$//' | tr '[:upper:]' '[:lower:]')

  # Extract version from config.toml using config-get.sh helper
  local version
  if [ -f "./Scripts/config-get.sh" ]; then
    version=$(./Scripts/config-get.sh "versions.${config_key}" config.toml 2>/dev/null)
  elif command -v dasel &> /dev/null; then
    version=$(dasel -r toml -f config.toml "versions.${config_key}" 2>/dev/null | tr -d "'\"")
  elif command -v yq &> /dev/null; then
    # Fallback to yq if dasel not available (requires toml support)
    version=$(yq -r ".versions.${config_key}" config.toml 2>/dev/null)
  else
    # Fallback to grep if neither dasel nor yq available
    version=$(grep "^${config_key}\s*=" config.toml | cut -d'"' -f2 2>/dev/null)
  fi

  if [ -n "$version" ] && [ "$version" != "null" ]; then
    echo "$version"
    return 0
  fi

  return 1
}

# Get version with intelligent fallback
get_version() {
  local version_var=$1
  local helm_chart_name=$2
  local source_path=$3

  local source_dir
  source_dir=$(dirname "$source_path")

  # Strategy 1: Try kustomization.yaml (for GitOps components)
  if [ -n "$helm_chart_name" ]; then
    local kustomize_version
    if kustomize_version=$(get_version_from_kustomize "$helm_chart_name" "$source_dir"); then
      echo "$kustomize_version"
      return
    fi
  fi

  # Strategy 2: Try config.toml (for infrastructure components)
  if [ -n "$version_var" ]; then
    local config_version
    if config_version=$(get_version_from_config "$version_var"); then
      echo "$config_version"
      return
    fi
  fi

  # Strategy 3: Fallback to latest
  echo "latest"
}

# Generate Chart.yaml for a component
generate_chart_yaml() {
  local component=$1
  local category=$2
  local description=$3
  local homepage=$4
  local source_path=$5
  local version_var=$6
  local helm_chart_name=$7

  local version
  version=$(get_version "$version_var" "$helm_chart_name" "$source_path")

  local output_dir="Docs/src/content/docs/implementation/components/${category}/${component}"
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

  # Determine source for version
  local version_source="kustomization.yaml"
  if [ -n "$version_var" ]; then
    version_source="config.toml"
  fi

  if [ "$version" = "latest" ]; then
    echo "Warning: $output_file - could not extract version from $version_source"
  fi
}

# Main execution
for component_spec in "${COMPONENTS[@]}"; do
  IFS='|' read -r name category description homepage source version_var helm_chart_name <<< "$component_spec"
  generate_chart_yaml "$name" "$category" "$description" "$homepage" "$source" "$version_var" "$helm_chart_name"
done
