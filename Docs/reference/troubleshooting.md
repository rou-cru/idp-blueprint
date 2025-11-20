# Troubleshooting

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
3. Ensure ports 30080 and 30443 are available
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

### Community Support

- Check the [GitHub Issues](https://github.com/rou-cru/idp-blueprint/issues) for similar problems
- Consider creating a new issue with detailed information about your problem
