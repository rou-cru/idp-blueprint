#!/usr/bin/env bash
# Lint Helm documentation - verify helm-docs would not make changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=Scripts/helm-docs-common.sh
source "$SCRIPT_DIR/helm-docs-common.sh"

# Callback function for linting documentation
# shellcheck disable=SC2317  # Called indirectly by helm_docs_foreach
lint_docs() {
  local template=$1
  local values_name=$2

  # Run helm-docs in dry-run mode (-d)
  # If it would make changes, it returns non-zero
  if helm-docs --template-files="$template" -d > /dev/null 2>&1; then
    echo "✅ $(pwd)/$values_name"
    return 0
  else
    echo "❌ $(pwd)/$values_name - helm-docs would make changes"
    return 1
  fi
}

# Run helm-docs lint for all values files
if helm_docs_foreach lint_docs; then
  exit 0
else
  exit 1
fi
