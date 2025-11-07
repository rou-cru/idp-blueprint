#!/bin/bash
# Generate documentation for all Helm values files using helm-docs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helm-docs-common.sh
source "$SCRIPT_DIR/helm-docs-common.sh"

# Callback function for generating documentation
generate_docs() {
  local template=$1
  local chart_dir=$2
  local source_values=$3

  # Generate documentation using helm-docs
  helm-docs --template-files="$template"

  # Rename README.md to index.md for MkDocs compatibility
  if [ -f "README.md" ]; then
    mv README.md index.md
    echo "  ✅ Generated: $(basename "$chart_dir")/index.md"
  else
    echo "  ⚠️  Warning: helm-docs did not generate README.md in $chart_dir" >&2
    return 1
  fi
}

echo "🔧 Generating component documentation with helm-docs..."
echo ""

# Run helm-docs for all components
if helm_docs_foreach generate_docs; then
  echo ""
  echo "✅ All component documentation generated successfully!"
  exit 0
else
  echo ""
  echo "❌ Some documentation generation failed"
  exit 1
fi
