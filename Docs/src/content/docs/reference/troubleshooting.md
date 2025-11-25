---
title: Troubleshooting
sidebar:
  label: Troubleshooting
  order: 9
---

This guide covers common issues and their solutions when working with the IDP Blueprint platform.

## Common Deployment Issues

### Docker Rate Limiting

**Symptoms**:

- Pull errors when starting containers
- "toomanyrequests" errors
- Failed deployments

**Solution**:

1. Ensure you are logged into Docker Hub: `docker login`
2. If using a free account, consider upgrading for higher rate limits
3. Pre-pull commonly used images: `docker pull <image>`

### Insufficient Resources

**Symptoms**:

- Deployments timing out
- Pods stuck in "Pending" state
- "Insufficient memory" or "Insufficient CPU" errors

**Solution**:

1. Check system resources: `htop` or `top`
2. Ensure minimum requirements are met (4+ cores, 8GB+ RAM)
3. Terminate other resource-intensive applications
4. Increase Docker Desktop resources if applicable

### Network Issues

**Symptoms**:

- Services not accessible via nip.io domains
- DNS resolution failures
- Connection timeouts

**Solution**:

1. Check firewall settings
2. Verify LAN IP detection: `ip route get 1.1.1.1 | awk '{print $7; exit}'`
3. Ensure the configured NodePorts (`nodeport_http`/`nodeport_https`) are available
4. Check if VPN is interfering with local network access

## Component-Specific Issues

### ArgoCD Not Accessible

1. Check if the ArgoCD server is running: `kubectl get pods -n argocd`
2. Verify the ingress/gateway is properly configured
3. Check if the certificate is valid: `kubectl get certificate -n argocd`
4. If needed, access directly via port-forward: `kubectl port-forward -n argocd svc/argocd-server 8080:80`

### Vault Initialization Problems

1. Check Vault pod status: `kubectl get pods -n vault-system`
2. Review Vault logs: `kubectl logs -n vault-system vault-0`
3. Verify if Vault is sealed:

   ```bash
   kubectl exec -n vault-system vault-0 -- vault status
   ```

4. If Vault is sealed and needs to be unsealed, use the initialization task:

   ```bash
   task vault:init
   ```

   This will unseal Vault and configure authentication for External Secrets Operator.

### Grafana Dashboard Issues

1. Check if Grafana is running: `kubectl get pods -n observability`
2. Verify datasource connections in Grafana settings
3. Check if Prometheus and Loki are accessible
4. Review Grafana logs for errors

## Diagnostic Commands

### Check All Deployments

```bash
kubectl get all -A
```

### Check ArgoCD Applications

```bash
kubectl get applications -A
```

### Check Certificates

```bash
kubectl get certificates,certificaterequests -A
```

### Check Vault Status

```bash
kubectl exec -n vault-system <vault-pod-name> -- vault status
```

### Check External Secrets

```bash
kubectl get externalsecrets,secretstores -A
```

## Debugging Workflows

### Enable Debug Logging

For most components, you can increase logging verbosity by modifying the appropriate values file before deployment.

### Check Component Status

```bash
# Check if all nodes are ready
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check all namespaces
kubectl get namespaces
```

## Reset and Cleanup

### Complete Platform Reset

```bash
task destroy
```

### Clean registry cache when needed

```bash
task registry:clean
```

### Clean Generated Documentation

```bash
task docs:clean
```

## Performance Issues

### Slow Deployment

1. Increase kubectl timeout: `KUBECTL_TIMEOUT=600s task deploy`
2. Check Docker image pull speeds
3. Ensure sufficient I/O performance on storage device

### High Memory Usage

1. Check resource limits in values files
2. Monitor actual usage vs. limits: `kubectl top nodes` and `kubectl top pods`
3. Consider scaling down non-essential components

## Getting Help

### Check Logs

Most issues can be diagnosed by checking component logs:

```bash
kubectl logs <pod-name> -n <namespace>
```

### Check Events

Kubernetes events can provide additional context:

```bash
kubectl get events -A --sort-by='.lastTimestamp'
```

## Platform-Specific Issues

This section covers issues specific to the IDP Blueprint platform architecture and components.

### ArgoCD Applications Stuck in Progressing

**Symptoms**:

- Applications show "Progressing" status indefinitely
- Sync appears to hang
- No error messages in ArgoCD UI

**Diagnosis**:

```bash
# Check Application status
kubectl -n argocd get application <app-name> -o yaml

# Check sync operation
kubectl -n argocd get application <app-name> \
  -o jsonpath='{.status.operationState.message}'

# Check for resource hooks
kubectl -n argocd get application <app-name> \
  -o jsonpath='{.status.operationState.syncResult.resources[*].hookPhase}'
```

**Common Causes & Solutions**:

1. **Sync wave dependencies not met**:
   - Check if earlier sync waves completed successfully
   - Verify resources with lower sync wave numbers are Healthy
   - Solution: `kubectl get all -A` and check for Failed pods

2. **Resource waiting for dependencies**:
   - ExternalSecrets waiting for Vault
   - Certificates waiting for cert-manager
   - Solution: Check dependency health first

3. **Resource hook stuck**:
   ```bash
   # Delete stuck hooks
   kubectl delete pod -n <namespace> -l argocd.argoproj.io/hook
   ```

4. **Self-heal conflicts**:
   - Manual changes being reverted repeatedly
   - Solution: Disable self-heal temporarily or commit changes to Git

---

### External Secrets Not Syncing from Vault

**Symptoms**:

- Kubernetes Secrets not created
- ExternalSecret shows "SecretSyncedError"
- Applications fail due to missing secrets

**Diagnosis**:

```bash
# Check ExternalSecret status
kubectl get externalsecrets -A

# Describe specific ExternalSecret
kubectl describe externalsecret -n <namespace> <name>

# Check SecretStore/ClusterSecretStore
kubectl get secretstore,clustersecretstore -A

# Check ESO controller logs
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets
```

**Common Causes & Solutions**:

1. **Vault not initialized or sealed**:
   ```bash
   kubectl exec -n vault-system vault-0 -- vault status
   # If sealed, run:
   task vault:init
   ```

2. **SecretStore authentication failed**:
   ```bash
   # Check ServiceAccount token
   kubectl get serviceaccount -n external-secrets-system external-secrets

   # Verify Vault Kubernetes auth is configured
   kubectl exec -n vault-system vault-0 -- \
     vault auth list
   ```

3. **Secret path doesn't exist in Vault**:
   ```bash
   # List secrets in Vault
   kubectl exec -n vault-system vault-0 -- \
     vault kv list secret/

   # Check specific path
   kubectl exec -n vault-system vault-0 -- \
     vault kv get secret/data/<path>
   ```

4. **ESO controller not running**:
   ```bash
   kubectl get pods -n external-secrets-system
   kubectl rollout restart deployment -n external-secrets-system external-secrets
   ```

---

### Kyverno Policy Blocking Deployments Unexpectedly

**Symptoms**:

- Resources fail to create with policy violation errors
- ArgoCD shows "SyncFailed" with Kyverno errors
- kubectl apply commands rejected

**Diagnosis**:

```bash
# Check policy reports
kubectl get policyreport,clusterpolicyreport -A

# Describe specific report
kubectl describe clusterpolicyreport <name>

# Check Kyverno admission controller logs
kubectl logs -n kyverno-system -l app.kubernetes.io/component=admission-controller

# Test policy against resource
kyverno apply /path/to/policy.yaml --resource /path/to/resource.yaml
```

**Common Causes & Solutions**:

1. **Missing required labels**:
   - Most common: namespace labels (`owner`, `business-unit`, `environment`)
   - Solution: Add labels to namespace definition
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: my-namespace
     labels:
       app.kubernetes.io/part-of: idp
       owner: platform-team
       business-unit: infrastructure
       environment: demo
   ```

2. **Resource limits not defined**:
   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
     limits:
       cpu: 500m
       memory: 512Mi
   ```

3. **Policy in enforce mode blocking expected resources**:
   - Check policy mode:
     ```bash
     kubectl get clusterpolicy <policy-name> \
       -o jsonpath='{.spec.validationFailureAction}'
     ```
   - Temporarily switch to audit mode:
     ```bash
     kubectl patch clusterpolicy <policy-name> \
       --type=merge -p '{"spec":{"validationFailureAction":"Audit"}}'
     ```

4. **Kyverno webhook not responding**:
   ```bash
   # Check webhook status
   kubectl get validatingwebhookconfigurations -l app.kubernetes.io/name=kyverno

   # Restart Kyverno
   kubectl rollout restart deployment -n kyverno-system kyverno-admission-controller
   ```

---

### Gateway Not Obtaining TLS Certificates

**Symptoms**:

- HTTPS services not accessible
- Certificate shows as "Not Ready"
- Browser shows "Certificate error" (not just self-signed warning)

**Diagnosis**:

```bash
# Check Gateway status
kubectl -n kube-system get gateway idp-gateway
kubectl describe gateway -n kube-system idp-gateway

# Check Certificate status
kubectl get certificate -A
kubectl describe certificate -n cert-manager idp-wildcard-cert

# Check CertificateRequest
kubectl get certificaterequest -A
kubectl describe certificaterequest -n cert-manager <name>

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

**Common Causes & Solutions**:

1. **cert-manager not ready**:
   ```bash
   kubectl get pods -n cert-manager
   kubectl rollout status deployment -n cert-manager cert-manager
   ```

2. **ClusterIssuer not configured**:
   ```bash
   kubectl get clusterissuer
   kubectl describe clusterissuer ca-issuer

   # Check CA secret exists
   kubectl get secret -n cert-manager idp-demo-ca-secret
   ```

3. **Certificate request failed**:
   ```bash
   # Check events
   kubectl get events -n cert-manager --field-selector reason=ErrIssuerRef

   # Manually trigger renewal
   kubectl annotate certificate -n cert-manager idp-wildcard-cert \
     cert-manager.io/issue-temporary-certificate="true" --overwrite
   ```

4. **HTTPRoute not referencing Certificate**:
   ```bash
   # Check HTTPRoute TLS configuration
   kubectl get httproute -A -o yaml | grep -A5 "tls:"
   ```

---

### Prometheus Not Scraping ServiceMonitors

**Symptoms**:

- Metrics missing in Grafana
- Prometheus targets show "DOWN" status
- ServiceMonitor created but targets not discovered

**Diagnosis**:

```bash
# Check ServiceMonitor exists
kubectl get servicemonitor -A

# Describe ServiceMonitor
kubectl describe servicemonitor -n <namespace> <name>

# Check Prometheus Operator logs
kubectl logs -n observability -l app.kubernetes.io/name=prometheus-operator

# Access Prometheus UI and check targets
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090
# Navigate to http://localhost:9090/targets
```

**Common Causes & Solutions**:

1. **ServiceMonitor label mismatch**:
   - ServiceMonitors must have label `prometheus: kube-prometheus`
   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     labels:
       prometheus: kube-prometheus  # Required!
   ```

2. **Selector doesn't match Service**:
   ```bash
   # Compare ServiceMonitor selector with Service labels
   kubectl get servicemonitor -n <namespace> <name> \
     -o jsonpath='{.spec.selector}'

   kubectl get service -n <namespace> <name> --show-labels
   ```

3. **Namespace not monitored**:
   - Check Prometheus serviceMonitorNamespaceSelector
   ```bash
   kubectl get prometheus -n observability kube-prometheus-stack-prometheus \
     -o jsonpath='{.spec.serviceMonitorNamespaceSelector}'
   ```

4. **Service port name doesn't match**:
   - ServiceMonitor endpoints.port must match Service port name
   ```yaml
   # ServiceMonitor
   endpoints:
   - port: metrics  # Must match Service port name

   # Service
   ports:
   - name: metrics  # Must match!
     port: 9090
   ```

---

### ArgoCD Application Health "Progressing" but Pods Stuck

**Symptoms**:

- ArgoCD shows application as "Progressing"
- Pods stuck in Pending, ContainerCreating, or CrashLoopBackOff
- Application never reaches "Healthy" state

**Diagnosis**:

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe stuck pod
kubectl describe pod -n <namespace> <pod-name>

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Common Causes & Solutions**:

1. **Image pull failures**:
   ```bash
   # Check ImagePullBackOff
   kubectl describe pod -n <namespace> <pod-name> | grep -A5 "Events:"

   # Solutions:
   # - Verify image exists: docker pull <image>
   # - Check docker login: docker login
   # - Check image pull secrets
   ```

2. **Resource constraints**:
   ```bash
   # Check if nodes have resources
   kubectl describe nodes | grep -A5 "Allocated resources"

   # Check PriorityClass
   kubectl get priorityclass

   # Solution: Scale down non-critical workloads or increase resources
   ```

3. **Volume mount failures**:
   ```bash
   # Check PVC status
   kubectl get pvc -n <namespace>

   # Describe PVC
   kubectl describe pvc -n <namespace> <pvc-name>
   ```

4. **Secret not available**:
   ```bash
   # Check if referenced secrets exist
   kubectl get secrets -n <namespace>

   # If using ExternalSecrets, check ESO status
   kubectl get externalsecrets -n <namespace>
   ```

---

### Community Support

- Check the [GitHub Issues](https://github.com/rou-cru/idp-blueprint/issues) for similar problems
- Consider creating a new issue with detailed information about your problem
