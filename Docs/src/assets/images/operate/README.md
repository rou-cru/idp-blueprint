# Operations Screenshots

This directory should contain screenshots illustrating operational procedures.

## Required Screenshots

### backup-scope.jpg
- **What to capture**: Diagram or visualization of backup scope and boundaries
- **Type**: Can be a screenshot of a Velero backup resource list or architecture diagram
- **Command**: `kubectl get backups -A` or custom diagram

### upgrade-canary.jpg
- **What to capture**: Visual representation of canary upgrade pattern
- **Type**: Screenshot of ArgoCD showing progressive rollout or diagram
- **Context**: Illustrates the upgrade strategy documented in upgrades.md

## How to Generate

1. For backup-scope: Create diagram showing what's included/excluded in backups
2. For upgrade-canary: Show ArgoCD Applications during a staged upgrade
3. Consider using tools like Excalidraw, D2, or screenshots from actual operations
