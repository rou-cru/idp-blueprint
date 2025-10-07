#!/bin/bash
set -e

# Configures the shell profile to source the project's init script for new terminals.
echo 'source .devcontainer/init.sh' >> ~/.profile