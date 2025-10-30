#!/bin/bash

ROOT_DIR=$(git rev-parse --show-toplevel)
TEMPLATE="$ROOT_DIR/.helm-docs-template.gotmpl"
EXIT_CODE=0

find . -type f -name '*-values.yaml' -printf '%h\n' | sort -u | while read -r dir; do
  values_file=$(find "$dir" -maxdepth 1 -name '*-values.yaml' -type f | head -1)

  if [ -n "$values_file" ]; then
    chart_name=$(basename "$dir")

    cd "$dir"
    echo "apiVersion: v2
name: $chart_name
version: 0.1.0" > Chart.yaml

    ln -sf "$(basename "$values_file")" values.yaml

    if ! helm-docs --template-files="$TEMPLATE" -d > /dev/null 2>&1; then
      echo "❌ $dir/$(basename "$values_file") - helm-docs failed"
      EXIT_CODE=1
    else
      echo "✅ $dir/$(basename "$values_file")"
    fi

    rm Chart.yaml values.yaml
    cd "$ROOT_DIR"
  fi
done

exit $EXIT_CODE
