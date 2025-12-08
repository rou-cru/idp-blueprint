#!/usr/bin/env bash
# Generate documentation for all Helm values files using helm-docs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=Scripts/helm-docs-common.sh
source "$SCRIPT_DIR/helm-docs-common.sh"

# Callback function for generating documentation
generate_docs() {
  local template=$1
  local values_name=$2
  local dir=$3
  local chart_name=$4
  local category=$5
  local component=$6
  local root_dir=$7

  helm-docs --template-files="$template"

  # Copy generated README.md into Docs so Astro can consume it
  local dest
  dest=$(docs_values_path "$root_dir" "$category" "$component" "$dir")
  mkdir -p "$(dirname "$dest")"
  cp "README.md" "$dest"
}

# Run helm-docs for all values files
helm_docs_foreach generate_docs
