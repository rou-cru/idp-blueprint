#!/bin/bash
# Lint Helm documentation - verify helm-docs would not make changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helm-docs-common.sh
source "$SCRIPT_DIR/helm-docs-common.sh"

# Callback function for linting documentation
# shellcheck disable=SC2317  # Called indirectly by helm_docs_foreach
lint_docs() {
  local template=$1
  local chart_dir=$2
  local source_values=$3

  local component_name
  component_name=$(basename "$chart_dir")

  # Check if index.md exists
  if [ ! -f "index.md" ]; then
    echo "⚠️  $component_name - missing index.md (run 'task docs:helm' to generate)"
    return 0  # Don't fail on missing docs, just warn
  fi

  # Run helm-docs in dry-run mode (-d)
  # If it would make changes, it returns non-zero
  if helm-docs --template-files="$template" -d > /dev/null 2>&1; then
    echo "✅ $component_name"
    return 0
  else
    echo "❌ $component_name - helm-docs would make changes (run 'task docs:helm' to update)"
    return 1
  fi
}

echo "🔍 Linting component documentation..."
echo ""

# Run helm-docs lint for all components
if helm_docs_foreach lint_docs; then
  echo ""
  echo "✅ All component documentation is up to date!"
  exit 0
else
  echo ""
  echo "❌ Some documentation is out of date or missing"
  exit 1
fi
