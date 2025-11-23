---
title: Common Operational Tasks
sidebar:
  label: Common Tasks
  order: 1
---

Quick reference for frequently performed platform operations. Each task includes a one-liner command for rapid execution.

## Cluster Operations

### Check Overall Cluster Health

```bash
# Quick health check - all pods across namespaces
kubectl get pods -A | grep -v Running | grep -v Completed

# Alternative with k9s (visual)
k9s -A
```

### View All ArgoCD Applications Status

```bash
# List all applications with sync/health status
kubectl get applications -n argocd

# Watch in real-time
kubectl get applications -n argocd -w

# Show only non-healthy applications
kubectl get applications -n argocd -o json | \
  jq -r '.items[] | select(.status.health.status != "Healthy") | .metadata.name'
```

### Restart Failed Pods

```bash
# Delete pods in non-Running state
kubectl get pods -A --field-selector=status.phase!=Running -o json | \
  jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
  xargs -n2 sh -c 'kubectl delete pod -n $0 $1'
```

---

## Secret Management

### Check External Secrets Status

```bash
# View all ExternalSecrets
kubectl get externalsecrets -A

# Check synchronization status
kubectl get externalsecrets -A -o json | \
  jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.status.conditions[] | select(.type=="Ready") | .status)"'

# Force refresh an ExternalSecret
kubectl annotate externalsecret -n <namespace> <name> \
  force-sync=$(date +%s) --overwrite
```

### Access Vault

```bash
# Get root token (demo/local only)
kubectl -n vault-system get secret vault-init \
  -o jsonpath='{.data.root-token}' | base64 -d; echo

# Check Vault status
kubectl exec -n vault-system vault-0 -- vault status

# List secrets in Vault
kubectl exec -n vault-system vault-0 -- vault kv list secret/
```

### Retrieve Service Credentials

```bash
# ArgoCD admin password
kubectl -n argocd get secret argocd-secret \
  -o jsonpath='{.data.admin\.password}' | base64 -d; echo

# Grafana admin password
kubectl -n observability get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo

# SonarQube admin password
kubectl -n cicd get secret sonarqube-admin-password \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

---

## GitOps Operations

### Refresh ArgoCD Application

```bash
# Refresh single application (detect changes without syncing)
kubectl patch application -n argocd <app-name> \
  --type merge -p '{"operation": {"initiatedBy": {"username": "manual"}, "sync": null}}'

# Alternative: use argocd CLI
argocd app get <app-name> --refresh
```

### Force Sync Application

```bash
# Hard refresh (ignore cache, re-run hooks)
argocd app sync <app-name> --force --prune

# Sync with kubectl
kubectl patch application -n argocd <app-name> \
  --type merge -p '{"operation": {"sync": {"syncStrategy": {"hook": {}}}}}'
```

### Disable Auto-Sync Temporarily

```bash
# Disable for investigation
kubectl patch application -n argocd <app-name> \
  --type merge -p '{"spec": {"syncPolicy": {"automated": null}}}'

# Re-enable
kubectl patch application -n argocd <app-name> \
  --type merge -p '{"spec": {"syncPolicy": {"automated": {"prune": true, "selfHeal": true}}}}'
```

---

## Observability

### Query Prometheus Metrics

```bash
# Port-forward to Prometheus
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090 &

# Example query (via curl)
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq .

# Check targets
curl -s 'http://localhost:9090/api/v1/targets' | jq '.data.activeTargets[] | {job, health}'
```

### Query Logs in Loki

```bash
# Port-forward to Loki
kubectl port-forward -n observability svc/loki 3100:3100 &

# Query logs (last hour)
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={namespace="argocd"}' \
  --data-urlencode "start=$(date -u -d '1 hour ago' +%s)000000000" \
  --data-urlencode "end=$(date -u +%s)000000000" | jq .
```

### View Recent Events

```bash
# Cluster-wide recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Filter by namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -A --watch
```

---

## Policy & Compliance

### Check Policy Reports

```bash
# View all ClusterPolicyReports
kubectl get clusterpolicyreport

# View namespace-specific PolicyReports
kubectl get policyreport -A

# Count violations by severity
kubectl get clusterpolicyreport -o json | \
  jq '.items[].results[] | select(.result == "fail") | .policy' | \
  sort | uniq -c | sort -rn
```

### Temporarily Disable a Policy

```bash
# Switch to audit mode
kubectl patch clusterpolicy <policy-name> \
  --type=merge -p '{"spec":{"validationFailureAction":"Audit"}}'

# Re-enable enforce mode
kubectl patch clusterpolicy <policy-name> \
  --type=merge -p '{"spec":{"validationFailureAction":"Enforce"}}'
```

### Check Resource Compliance

```bash
# Find resources without required labels
kubectl get all -A -o json | \
  jq -r '.items[] | select(.metadata.labels.owner == null) | "\(.kind)/\(.metadata.name) in \(.metadata.namespace)"'

# Check pods without resource limits
kubectl get pods -A -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"'
```

---

## Certificate Management

### Check Certificate Status

```bash
# View all certificates
kubectl get certificate -A

# Check specific certificate details
kubectl describe certificate -n cert-manager idp-wildcard-cert

# Verify TLS secrets exist
kubectl get secret -A | grep kubernetes.io/tls
```

### Force Certificate Renewal

```bash
# Trigger renewal
kubectl annotate certificate -n cert-manager idp-wildcard-cert \
  cert-manager.io/issue-temporary-certificate="true" --overwrite

# Delete and recreate certificate
kubectl delete certificate -n cert-manager idp-wildcard-cert
kubectl apply -f IT/cert-manager/
```

---

## Networking

### Check Gateway Status

```bash
# View Gateway resource
kubectl get gateway -n kube-system idp-gateway

# Describe for detailed status
kubectl describe gateway -n kube-system idp-gateway

# Check HTTPRoutes
kubectl get httproute -A
```

### Test Service Connectivity

```bash
# Check if service is reachable internally
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  wget -qO- http://<service-name>.<namespace>.svc.cluster.local

# Check DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  nslookup <service-name>.<namespace>.svc.cluster.local
```

### View Network Policies

```bash
# List all NetworkPolicies
kubectl get networkpolicies -A

# Describe specific policy
kubectl describe networkpolicy -n <namespace> <policy-name>
```

---

## Resource Management

### Check Resource Usage

```bash
# Node resource utilization
kubectl top nodes

# Pod resource utilization
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu

# Check allocated vs available
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### View Resource Quotas

```bash
# Check quotas across namespaces
kubectl get resourcequota -A

# Detailed quota usage
kubectl describe resourcequota -n <namespace>
```

### Scale Deployments

```bash
# Scale specific deployment
kubectl scale deployment -n <namespace> <deployment-name> --replicas=<count>

# Scale all deployments in namespace to 0 (maintenance)
kubectl get deployments -n <namespace> -o name | \
  xargs -I {} kubectl scale {} --replicas=0 -n <namespace>
```

---

## Backup & Recovery

### Create Backup (if Velero installed)

```bash
# Full cluster backup
velero backup create full-backup-$(date +%Y%m%d-%H%M%S) --wait

# Namespace-specific backup
velero backup create <namespace>-backup --include-namespaces=<namespace>

# Check backup status
velero backup get
```

### Export Important Configurations

```bash
# Export all ArgoCD Applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Export all secrets (encrypted)
kubectl get secrets -A -o yaml > secrets-backup.yaml

# Export Kyverno policies
kubectl get clusterpolicies -o yaml > policies-backup.yaml
```

---

## Debugging

### Get Logs from Multiple Pods

```bash
# All pods with specific label
kubectl logs -n <namespace> -l app=<app-name> --all-containers --tail=100

# Previous container logs (for CrashLoopBackOff)
kubectl logs -n <namespace> <pod-name> --previous

# Stream logs from all pods in namespace
kubectl logs -n <namespace> --all-containers -f
```

### Execute Commands in Pods

```bash
# Interactive shell
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Run one-off command
kubectl exec -n <namespace> <pod-name> -- env

# Execute in specific container (multi-container pod)
kubectl exec -it -n <namespace> <pod-name> -c <container-name> -- /bin/sh
```

### Port Forward for Local Access

```bash
# Forward single port
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<remote-port>

# Common examples
kubectl port-forward -n argocd svc/argocd-server 8080:443
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80
kubectl port-forward -n vault-system svc/vault 8200:8200
```

---

## Platform Maintenance

### Update Component Version

```bash
# Edit kustomization.yaml to update Helm chart version
cd K8s/<stack>/<component>/
# Update version in kustomization.yaml
git add kustomization.yaml
git commit -m "update: <component> to version <new-version>"
git push

# ArgoCD will auto-sync and deploy the new version
```

### Clean Up Completed Jobs

```bash
# Delete completed jobs older than 1 day
kubectl get jobs -A --field-selector status.successful=1 -o json | \
  jq -r '.items[] | select(.status.completionTime | fromdateiso8601 < (now - 86400)) | "\(.metadata.namespace) \(.metadata.name)"' | \
  xargs -n2 sh -c 'kubectl delete job -n $0 $1'
```

### Restart All Pods in Deployment

```bash
# Rollout restart (zero-downtime)
kubectl rollout restart deployment -n <namespace> <deployment-name>

# Watch rollout status
kubectl rollout status deployment -n <namespace> <deployment-name>
```

---

## Quick Diagnostic Commands

### Platform Health Check (One-Liner)

```bash
# Check critical components in one command
echo "=== Nodes ===" && kubectl get nodes && \
echo "=== ArgoCD Apps ===" && kubectl get apps -n argocd | grep -v Healthy && \
echo "=== Failed Pods ===" && kubectl get pods -A | grep -v Running | grep -v Completed && \
echo "=== Certificates ===" && kubectl get cert -A | grep -v True
```

### Generate Support Bundle

```bash
# Collect diagnostics for troubleshooting
mkdir -p support-bundle
kubectl get all -A > support-bundle/all-resources.txt
kubectl get events -A --sort-by='.lastTimestamp' > support-bundle/events.txt
kubectl get applications -n argocd -o yaml > support-bundle/argocd-apps.yaml
kubectl get clusterpolicies -o yaml > support-bundle/policies.yaml
kubectl describe nodes > support-bundle/nodes.txt
tar -czf support-bundle-$(date +%Y%m%d-%H%M%S).tar.gz support-bundle/
```

---

## See Also

- [Troubleshooting](../reference/troubleshooting.md) - Detailed problem diagnosis
- [URLs & Credentials](../reference/urls-credentials.md) - Service access information
- [Taskfile Commands](../reference/taskfile-commands.md) - Platform-specific task commands
- [Disaster Recovery](../operate/disaster-recovery.md) - Recovery procedures
