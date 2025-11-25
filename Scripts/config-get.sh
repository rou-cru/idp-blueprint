#!/usr/bin/env bash
# Config value getter - centralizes dasel TOML reading with proper quote stripping
#
# Usage:
#   ./Scripts/config-get.sh <key> [config_file]
#
# Examples:
#   ./Scripts/config-get.sh passwords.argocd_admin
#   ./Scripts/config-get.sh versions.cilium config.toml
#
# Note: dasel returns string values wrapped in single quotes ('value').
# This script strips both single and double quotes for clean output.

set -euo pipefail

KEY="${1:-}"
CONFIG_FILE="${2:-config.toml}"

if [[ -z "$KEY" ]]; then
  echo "Usage: $0 <key> [config_file]" >&2
  exit 1
fi

dasel -r toml -f "$CONFIG_FILE" "$KEY" 2>/dev/null | tr -d "'\""
