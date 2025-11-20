#!/usr/bin/env bash
set -euo pipefail

# Resolve repository root even when Codex does not expand ${workspaceFolder}.
if [[ -n "${WORKSPACE_FOLDER:-}" && -d "${WORKSPACE_FOLDER}" ]]; then
  REPO_ROOT="${WORKSPACE_FOLDER}"
elif [[ -n "${CODEX_WORKSPACE:-}" && -d "${CODEX_WORKSPACE}" ]]; then
  REPO_ROOT="${CODEX_WORKSPACE}"
elif git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  REPO_ROOT="${git_root}"
else
  SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

DB_PATH="${REPO_ROOT}/.memory/graph.db"

if [[ ! -f "${DB_PATH}" ]]; then
  echo "memory-mcp-server-go: database not found at ${DB_PATH}" >&2
  exit 1
fi

exec memory-mcp-server-go -memory "${DB_PATH}"
