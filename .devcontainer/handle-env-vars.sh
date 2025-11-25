#!/usr/bin/env bash
set -e

# Configures the shell profile to source the project's init script for new terminals.
if ! grep -q 'source .devcontainer/init.sh' ~/.profile 2>/dev/null; then
    echo 'source .devcontainer/init.sh' >> ~/.profile
fi