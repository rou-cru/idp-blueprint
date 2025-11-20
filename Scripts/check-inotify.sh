#!/usr/bin/env bash
# Check and fix inotify limits for Kubernetes controllers (Linux only)

set -euo pipefail

REQUIRED_INSTANCES=512
REQUIRED_WATCHES=524288

CURRENT_INSTANCES=$(cat /proc/sys/fs/inotify/max_user_instances)
CURRENT_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)

NEEDS_FIX=false

if [ "$CURRENT_INSTANCES" -lt "$REQUIRED_INSTANCES" ]; then
  echo "WARNING: fs.inotify.max_user_instances is $CURRENT_INSTANCES (required: $REQUIRED_INSTANCES)"
  NEEDS_FIX=true
fi

if [ "$CURRENT_WATCHES" -lt "$REQUIRED_WATCHES" ]; then
  echo "WARNING: fs.inotify.max_user_watches is $CURRENT_WATCHES (required: $REQUIRED_WATCHES)"
  NEEDS_FIX=true
fi

if [ "$NEEDS_FIX" = "true" ]; then
  echo ""
  echo "Insufficient inotify limits can cause 'too many open files' errors in Kubernetes controllers."
  echo ""
  read -rp "Do you want to fix these limits now? (requires sudo) [y/N]: " CONFIRM

  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    echo "Applying inotify limits..."
    sudo sysctl -w fs.inotify.max_user_instances=$REQUIRED_INSTANCES
    sudo sysctl -w fs.inotify.max_user_watches=$REQUIRED_WATCHES

    # Make persistent
    if ! grep -q "fs.inotify.max_user_instances" /etc/sysctl.conf 2>/dev/null; then
      echo "fs.inotify.max_user_instances=$REQUIRED_INSTANCES" | sudo tee -a /etc/sysctl.conf
    fi
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf 2>/dev/null; then
      echo "fs.inotify.max_user_watches=$REQUIRED_WATCHES" | sudo tee -a /etc/sysctl.conf
    fi

    echo "INFO: inotify limits updated successfully."
  else
    echo "Skipping inotify fix"
  fi
else
  echo "INFO: inotify limits are sufficient."
fi
