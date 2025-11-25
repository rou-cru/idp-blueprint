# ArgoCD Sync-Wave Strategy

## Overview

This document describes the sync-wave strategy used in the IDP Blueprint project to ensure proper ordering of resource deployment via ArgoCD while avoiding over-engineering and maintaining flexibility.

## Critical Context: IT/ Directory

**IMPORTANT**: The `IT/` directory is **NOT** managed by ArgoCD. All resources in `IT/` are deployed manually via `kubectl` and `helm` commands (see `Taskfile.yaml`) during the bootstrap phase **BEFORE** ArgoCD exists.

Therefore:
- Any `argocd.argoproj.io/sync-wave` annotations in `IT/` files are **useless** and should be removed
- Sync-wave strategy only applies to resources in `K8s/` and `Policies/` directories
- IT/ resources include: namespaces, gateway, HTTPRoutes, priority classes, CNI, CSI drivers, and cert-manager

## Sync-Wave Hierarchy (ArgoCD-Managed Resources Only)

### Wave 0: Foundation
- **Policies/namespace.yaml**: Kyverno namespace
- **K8s/*/governance/namespace.yaml**: Security, devx, observability namespaces
- **Purpose**: Ensure namespaces exist before deployments

### Wave 1: Policy Engine
- **Policies/kustomization.yaml**: Kyverno deployment + policies
- **Purpose**: Deploy admission webhook before resources that will be validated

### Wave 2: Security Scanning
- **K8s/security/trivy/kustomization.yaml**: Trivy operator
- **Purpose**: Deploy after Kyverno webhook is ready to validate scan jobs

### Wave 3+: Application Resources
- SecretStores, ExternalSecrets, and application deployments
- Most resources don't need explicit sync-waves

## Key Principles

1. **Minimal Sync-Waves**: Only use sync-waves where real dependencies exist. Over-use causes rigidity and unexpected problems.

2. **Health Checks Matter**: Sync-waves alone don't prevent race conditions. Combine with proper readiness/startup probes.

3. **ArgoCD Waits for Health**: ArgoCD won't proceed to next wave until all resources in current wave are healthy.

4. **Kyverno-Specific Configuration**:
   - `readinessProbe.initialDelaySeconds: 10` - Wait for webhook registration
   - `readinessProbe.periodSeconds: 5` - Frequent health checks
   - `readinessProbe.failureThreshold: 6` - Allow tolerance for startup
   - `startupProbe.initialDelaySeconds: 15` - Give time for initialization
   - `startupProbe.failureThreshold: 40` - Allow up to 215s total startup time

## When to Add Sync-Waves

Add sync-waves ONLY when:
1. Resource A creates webhooks/controllers that validate resource B
2. Resource A must exist before B can function (hard dependency)
3. Race conditions have been observed in practice

Do NOT add sync-waves for:
- Resources that can tolerate retries (most applications)
- Resources with soft dependencies
- "Just to be safe" scenarios

## Solved Problem: Kyverno ↔ Trivy Race Condition

**Problem**: Trivy operator creates scan jobs during startup. Kyverno admission webhook validates these jobs. If Trivy starts before Kyverno webhook is ready, job creation fails with "no endpoints available for service kyverno-svc".

**Solution**:
1. Kyverno deploys in wave 1 with improved health checks
2. Trivy deploys in wave 2 (after Kyverno is healthy)
3. ArgoCD guarantees Kyverno webhook is ready before Trivy creates jobs

## Common Patterns

### Adding Sync-Wave to Kustomization
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonAnnotations:
  argocd.argoproj.io/sync-wave: "1"

helmCharts:
  - name: component-name
    # ...
```

### Adding Sync-Wave to Individual Resource
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: example
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

## Troubleshooting

**Symptom**: Resources fail with webhook errors during deployment
**Check**: Is the webhook service deployed in an earlier wave than resources it validates?

**Symptom**: Deployment takes too long / times out
**Check**: Are sync-waves forcing unnecessary sequential deployment? Can some waves be merged?

**Symptom**: Resources in IT/ not respecting sync-waves
**Check**: Remember IT/ is deployed manually before ArgoCD exists. Sync-waves have no effect there.

## Future Considerations

When adding new components:
1. Check if it creates webhooks or controllers → needs earlier wave than consumers
2. Check if it depends on policy validation → needs later wave than Kyverno
3. Default to NO sync-wave unless dependency is clear
4. Test fresh deployments to verify ordering works
