# Verification Screenshots

This directory should contain screenshots for the "Verify Installation" guide, showing what users should expect during the first 5-10 minutes after deployment.

## Required Screenshots

### argocd-apps.jpg
- **What to capture**: ArgoCD Applications view showing apps appearing and converging
- **URL**: `https://argocd.<ip>.nip.io`
- **View**: Applications grid/list view
- **Expected state**: Mix of Syncing/Progressing and Healthy states (early deployment phase)

### k9s-overview.jpg
- **What to capture**: k9s showing pods across namespaces settling
- **Command**: `k9s -A`
- **View**: Pods view with sorting by status
- **Expected state**: Some pods in ContainerCreating, some Running

### grafana-home.jpg
- **What to capture**: Grafana home with Prometheus/Loki datasources wired
- **URL**: `https://grafana.<ip>.nip.io`
- **View**: Home dashboard
- **Expected state**: Datasources configured and reachable

## How to Generate

1. Deploy the platform: `task deploy`
2. Immediately after deployment completes, capture screenshots
3. Show the "eventual consistency" phase (not everything green yet)
4. Save with exact filenames listed above
