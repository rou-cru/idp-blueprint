#!/bin/bash
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

# Process each component directory containing Chart.yaml in docs_src/components/
# Arguments:
#   $1: callback function to execute (receives: template_path, chart_dir, source_values_path)
# Returns:
#   0 on success, 1 if any callback failed
helm_docs_foreach() {
  local callback=$1
  local exit_code=0

  validate_git_repo || return 1

  local root_dir
  root_dir=$(git rev-parse --show-toplevel)
  local template="$root_dir/.helm-docs-template.gotmpl"

  if [ ! -f "$template" ]; then
    echo "Error: Template file not found: $template" >&2
    return 1
  fi

  # Find all Chart.yaml files in docs_src/components/ subdirectories
  while IFS= read -r chart_file; do
    local chart_dir
    chart_dir=$(dirname "$chart_file")

    # Extract source path from Chart.yaml annotations
    local source_path
    source_path=$(grep "idp.blueprint/source:" "$chart_file" | awk '{print $2}' | tr -d '"')

    if [ -z "$source_path" ]; then
      echo "⚠️  Warning: No source path found in $chart_file, skipping..." >&2
      continue
    fi

    local source_values="$root_dir/$source_path"

    if [ ! -f "$source_values" ]; then
      echo "⚠️  Warning: Source values file not found: $source_values, skipping..." >&2
      continue
    fi

    # Navigate to component directory
    cd "$chart_dir" || {
      echo "Error: Cannot change to directory: $chart_dir" >&2
      return 1
    }

    # Validate symlink doesn't exist before creating
    if [ -e values.yaml ] && [ ! -L values.yaml ]; then
      echo "Error: values.yaml already exists and is not a symlink in $chart_dir" >&2
      return 1
    fi

    # Create temporary symlink to source values file
    ln -sf "$source_values" values.yaml

    # Setup cleanup trap for temporary symlink
    cleanup_temp_symlink() {
      rm -f "$chart_dir/values.yaml"
    }
    trap cleanup_temp_symlink EXIT INT TERM

    # Execute callback
    if ! "$callback" "$template" "$chart_dir" "$source_values"; then
      exit_code=1
    fi

    # Cleanup temporary symlink
    cleanup_temp_symlink
    trap - EXIT INT TERM

    # Return to root directory
    cd "$root_dir" || {
      echo "Error: Cannot return to root directory: $root_dir" >&2
      return 1
    }
  done < <(find "$root_dir/docs_src/components" -type f -name "Chart.yaml" | sort)

  return $exit_code
}
