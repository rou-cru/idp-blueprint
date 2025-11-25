# After Deploy Screenshots

This directory should contain screenshots showing the platform state immediately after a successful deployment.

## Required Screenshots

### argocd-apps-healthy.jpg
- **What to capture**: ArgoCD UI showing all Applications in "Healthy" and "Synced" state
- **URL**: `https://argocd.<ip>.nip.io`
- **View**: Applications list view
- **Expected state**: All apps showing green health status and sync icons

### k9s-overview.jpg
- **What to capture**: k9s terminal UI showing pods across all namespaces
- **Command**: `k9s -A`
- **View**: Pods view (`:pods`)
- **Expected state**: All pods in Running status with Ready status

### grafana-home.jpg
- **What to capture**: Grafana home dashboard with datasources visible
- **URL**: `https://grafana.<ip>.nip.io`
- **View**: Home dashboard
- **Expected state**: Prometheus and Loki datasources showing as connected

## How to Generate

1. Deploy the platform: `task deploy`
2. Wait for all applications to reach Healthy/Synced state
3. Take screenshots following the guide above
4. Save with exact filenames listed above
5. Optimize images: `optipng *.png` or `jpegoptim *.jpg`
