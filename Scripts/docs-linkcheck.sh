#!/usr/bin/env bash
# Check for broken internal links in documentation

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

DOCS_DIR="Docs/src/content/docs"
EXIT_CODE=0

# Find all markdown files and check internal links
while IFS= read -r file; do
  while IFS= read -r link; do
    # Skip external links and anchors
    if [[ "$link" =~ ^https?:// ]] || [[ "$link" =~ ^# ]]; then
      continue
    fi

    # Remove anchor from link and resolve path
    link_path="${link%%#*}"
    file_dir=$(dirname "$file")
    full_path=$(realpath -m "$file_dir/$link_path" 2>/dev/null || echo "$file_dir/$link_path")

    if [ ! -f "$full_path" ]; then
      echo "Broken link in $file: $link -> $full_path"
      EXIT_CODE=1
    fi
  done < <(grep -oP '\[([^\]]+)\]\(\K[^)]+(?=\))' "$file" 2>/dev/null || true)
done < <(find "$DOCS_DIR" -type f \( -name "*.md" -o -name "*.mdx" \))

exit $EXIT_CODE
