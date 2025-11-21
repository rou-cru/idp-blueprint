#!/usr/bin/env bash
# Common functions for helm-docs scripts
# This file should be sourced, not executed directly

set -euo pipefail

# Validate we're in a git repository
validate_git_repo() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Error: Must run from within a git repository" >&2
    return 1
  fi
}

resolve_category_component() {
  local dir=$1
  case "$dir" in
    ./IT/*) echo "infrastructure|$(basename "$dir")" ;;
    ./K8s/observability/*) echo "observability|$(basename "$dir")" ;;
    ./K8s/cicd/*) echo "cicd|$(basename "$dir")" ;;
    ./K8s/security/*) echo "security|$(basename "$dir")" ;;
    ./K8s/events/*) echo "eventing|$(basename "$dir")" ;;
    ./Policies/*) echo "policy|$(basename "$dir")" ;;
    *) echo "unknown|$(basename "$dir")" ;;
  esac
}

# Read version for GitOps components from nearest kustomization.yaml
get_version_from_kustomize() {
  local helm_chart_name=$1
  local dir=$2

  local kustomize_file="$dir/kustomization.yaml"
  if [ ! -f "$kustomize_file" ]; then
    kustomize_file="$(dirname "$dir")/kustomization.yaml"
  fi
  if [ ! -f "$kustomize_file" ]; then
    kustomize_file="$(dirname "$(dirname "$dir")")/kustomization.yaml"
  fi

  if [ ! -f "$kustomize_file" ]; then
    return 1
  fi

  if command -v yq >/dev/null 2>&1; then
    local version
    version=$(yq -r ".helmCharts[] | select(.name == \"$helm_chart_name\" or .valuesFile == \"values.yaml\") | .version" "$kustomize_file" 2>/dev/null)
    if [ -n "$version" ] && [ "$version" != "null" ]; then
      echo "$version"
      return 0
    fi
  fi
  return 1
}

# Read version for infra components from config.toml
get_version_from_config() {
  local component=$1
  local key
  key=$(echo "$component" | tr '-' '_' )

  if [ -f "./Scripts/config-get.sh" ]; then
    local version
    version=$(./Scripts/config-get.sh "versions.${key}" config.toml 2>/dev/null)
    if [ -n "$version" ] && [ "$version" != "null" ]; then
      echo "$version"
      return 0
    fi
  fi

  if command -v dasel >/dev/null 2>&1; then
    local version
    version=$(dasel -r toml -f config.toml "versions.${key}" 2>/dev/null | tr -d "'\"")
    if [ -n "$version" ] && [ "$version" != "null" ]; then
      echo "$version"
      return 0
    fi
  fi

  if command -v yq >/dev/null 2>&1; then
    local version
    version=$(yq -r ".versions.${key}" config.toml 2>/dev/null)
    if [ -n "$version" ] && [ "$version" != "null" ]; then
      echo "$version"
      return 0
    fi
  fi

  return 1
}

# Determine chart name/version for a values directory
resolve_chart_meta() {
  local dir=$1
  local component
  component=$(basename "$dir")

  local chart_name="$component"
  local version="latest"

  if version_from_kust=$(get_version_from_kustomize "$chart_name" "$dir"); then
    version="$version_from_kust"
  elif version_from_cfg=$(get_version_from_config "$component"); then
    version="$version_from_cfg"
  fi

  echo "$chart_name|$version"
}

map_component_alias() {
  local dir=$1
  local component=$2
  case "$dir" in
    *kube-prometheus-stack*) echo "prometheus" ;;
    *) echo "$component" ;;
  esac
}

docs_values_path() {
  local root_dir=$1
  local category=$2
  local component=$3
  local dir=$4
  local alias
  alias=$(map_component_alias "$dir" "$component")
  echo "$root_dir/Docs/components/${category}/${alias}/_values.generated.md"
}

# Process each directory containing values.yaml files
# Arguments:
#   $1: callback function to execute (receives: template_path, values_file_name, dir, chart_name, category, component, root_dir)
# Returns:
#   0 on success, 1 if any callback failed
helm_docs_foreach() {
  local callback=$1
  local exit_code=0

  validate_git_repo || return 1

  local root_dir
  root_dir=$(git rev-parse --show-toplevel)
  local template="$root_dir/.config/helm-docs/template.gotmpl"

  if [ ! -f "$template" ]; then
    echo "Error: Template file not found: $template" >&2
    return 1
  fi

  # Find all directories containing values.yaml files
  # Using dirname instead of -printf for macOS compatibility
  while read -r dir; do
    local values_file
    values_file=$(find "$dir" -maxdepth 1 -name 'values.yaml' -type f | head -1)

    if [ -n "$values_file" ]; then
      local values_name
      values_name=$(basename "$values_file")

      # Resolve category/component and chart metadata
      local category component chart_meta chart_name chart_version
      IFS='|' read -r category component <<< "$(resolve_category_component "$dir")"
      chart_meta=$(resolve_chart_meta "$dir")
      IFS='|' read -r chart_name chart_version <<< "$chart_meta"

      # Setup cleanup trap for temporary files
      cleanup_temp_files() {
        rm -f "$dir/Chart.yaml"
      }
      trap cleanup_temp_files EXIT INT TERM

      # Navigate to target directory
      cd "$dir" || {
        echo "Error: Cannot change to directory: $dir" >&2
        cleanup_temp_files
        trap - EXIT INT TERM
        return 1
      }

      # Create temporary Chart.yaml
      cat > Chart.yaml <<EOF
apiVersion: v2
name: $chart_name
version: $chart_version
EOF

      # Execute callback
      if ! "$callback" "$template" "$values_name" "$dir" "$chart_name" "$category" "$component" "$root_dir"; then
        exit_code=1
      fi

      # Cleanup temporary files
      cleanup_temp_files
      trap - EXIT INT TERM

      # Return to root directory
      cd "$root_dir" || {
        echo "Error: Cannot return to root directory: $root_dir" >&2
        return 1
      }
    fi
  done < <(find . -type f -name 'values.yaml' -exec dirname {} \; | sort -u)

  return $exit_code
}
