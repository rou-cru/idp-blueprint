#!/bin/bash
# Check for broken links in documentation
# This script validates both internal and external links in markdown files

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

DOCS_DIR="Docs"
DOCS_BUILD_DIR="site"
EXIT_CODE=0

echo "🔍 Checking documentation links..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if docs are built
if [ ! -d "$DOCS_BUILD_DIR" ]; then
  echo -e "${YELLOW}⚠️  Warning: Built documentation not found at '$DOCS_BUILD_DIR'${NC}"
  echo "   Run 'task docs:build' first for full link validation"
  echo ""
fi

# Function to check internal markdown links
check_internal_links() {
  echo "📄 Checking internal markdown links..."
  local broken_links=0

  # Find all markdown files
  while IFS= read -r file; do
    # Extract markdown links [text](path)
    while IFS= read -r link; do
      # Skip external links (http/https)
      if [[ "$link" =~ ^https?:// ]]; then
        continue
      fi

      # Skip anchors only
      if [[ "$link" =~ ^# ]]; then
        continue
      fi

      # Remove anchor from link
      local link_path="${link%%#*}"

      # Resolve relative path
      local file_dir=$(dirname "$file")
      local full_path="$file_dir/$link_path"

      # Normalize path
      full_path=$(realpath -m "$full_path" 2>/dev/null || echo "$full_path")

      # Check if file exists
      if [ ! -f "$full_path" ]; then
        echo -e "${RED}✗${NC} Broken link in $file"
        echo "  Link: $link"
        echo "  Expected: $full_path"
        echo ""
        broken_links=$((broken_links + 1))
      fi
    done < <(grep -oP '\[([^\]]+)\]\(\K[^)]+(?=\))' "$file" 2>/dev/null || true)
  done < <(find "$DOCS_DIR" -type f -name "*.md")

  if [ $broken_links -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All internal links are valid"
  else
    echo -e "${RED}✗${NC} Found $broken_links broken internal link(s)"
    EXIT_CODE=1
  fi
  echo ""
}

# Function to check external links (HTTP/HTTPS)
check_external_links() {
  echo "🌐 Checking external links (this may take a while)..."
  local broken_links=0
  local checked_links=()

  # Extract all HTTP/HTTPS links from markdown files
  while IFS= read -r file; do
    while IFS= read -r url; do
      # Skip if already checked
      if [[ " ${checked_links[@]} " =~ " ${url} " ]]; then
        continue
      fi

      checked_links+=("$url")

      # Check if URL is reachable (timeout 10s)
      if curl -s -f -L --max-time 10 --retry 2 --head "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $url"
      else
        echo -e "${RED}✗${NC} Broken: $url"
        echo "  Found in: $file"
        broken_links=$((broken_links + 1))
        EXIT_CODE=1
      fi
    done < <(grep -oP 'https?://[^\s\)\"<>]+' "$file" 2>/dev/null || true)
  done < <(find "$DOCS_DIR" -type f -name "*.md")

  echo ""
  if [ $broken_links -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All external links are reachable"
  else
    echo -e "${YELLOW}⚠️  Found $broken_links unreachable external link(s)${NC}"
    echo "   Note: Some links may be temporarily unavailable"
  fi
  echo ""
}

# Function to check built site links (if available)
check_built_site() {
  if [ ! -d "$DOCS_BUILD_DIR" ]; then
    return
  fi

  echo "🏗️  Checking built HTML site..."

  # Simple check for common issues
  local issues=0

  # Check if index.html exists
  if [ ! -f "$DOCS_BUILD_DIR/index.html" ]; then
    echo -e "${RED}✗${NC} Missing index.html"
    issues=$((issues + 1))
  fi

  # Check if sitemap.xml exists
  if [ ! -f "$DOCS_BUILD_DIR/sitemap.xml" ]; then
    echo -e "${YELLOW}⚠️${NC}  Missing sitemap.xml"
  fi

  # Check for 404 page
  if [ ! -f "$DOCS_BUILD_DIR/404.html" ]; then
    echo -e "${YELLOW}⚠️${NC}  Missing 404.html"
  fi

  if [ $issues -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Built site structure looks good"
  else
    EXIT_CODE=1
  fi
  echo ""
}

# Main execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Documentation Link Checker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_internal_links
check_external_links
check_built_site

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
else
  echo -e "${YELLOW}⚠️  Some checks failed (see above)${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $EXIT_CODE
