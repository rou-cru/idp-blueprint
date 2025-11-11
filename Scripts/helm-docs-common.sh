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

# Process each directory containing *-values.yaml files
# Arguments:
#   $1: callback function to execute (receives: template_path, values_file_name)
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

  # Find all directories containing *-values.yaml files
  # Using dirname instead of -printf for macOS compatibility
  while read -r dir; do
    local values_file
    values_file=$(find "$dir" -maxdepth 1 -name '*-values.yaml' -type f | head -1)

    if [ -n "$values_file" ]; then
      local chart_name
      chart_name=$(basename "$dir")
      local values_name
      values_name=$(basename "$values_file")

      # Setup cleanup trap for temporary files
      cleanup_temp_files() {
        rm -f "$dir/Chart.yaml" "$dir/values.yaml"
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
version: 0.1.0
EOF

      # Create symlink to values file
      ln -sf "$values_name" values.yaml

      # Execute callback
      if ! "$callback" "$template" "$values_name"; then
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
  done < <(find . -type f -name '*-values.yaml' -exec dirname {} \; | sort -u)

  return $exit_code
}
