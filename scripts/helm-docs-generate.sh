#!/bin/bash
# Generate documentation for all Helm values files using helm-docs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helm-docs-common.sh"

# Callback function for generating documentation
generate_docs() {
  local template=$1
  local values_name=$2

  helm-docs --template-files="$template"
}

# Run helm-docs for all values files
helm_docs_foreach generate_docs
