# Health Probes Strategy

## Overview

This document defines the health probe strategy used across the IDP Blueprint project. It serves as a reference for implementing consistent, robust health checks in all components, ensuring optimal startup times while maintaining reliability.

## Core Principles

### 1. Startup Probe Pattern (Recommended)

**When to use**: All components with variable or slow startup times (>15s)

**Benefits**:
- Separates startup concerns from runtime health checks
- Allows aggressive liveness/readiness probes after startup completes
- Prevents premature pod restarts during initialization

**Standard configuration**:
```yaml
startupProbe:
  httpGet:  # or exec for custom commands
    path: /ready  # or appropriate health endpoint
    port: http-metrics
  initialDelaySeconds: 10-30  # Conservative estimate
  periodSeconds: 5-10         # Check frequency
  failureThreshold: 12-20     # Total startup window: initialDelay + (period * failures)
  timeoutSeconds: 1-5         # Based on endpoint complexity
```

### 2. Liveness Probe Pattern

**Purpose**: Detect deadlocks, infinite loops, or unresponsive processes

**Key insight**: With startup probe, liveness can be aggressive (initialDelaySeconds: 0)

**Standard configuration**:
```yaml
livenessProbe:
  httpGet:
    path: /livez  # or /healthz
    port: 8081
  initialDelaySeconds: 0   # Startup probe handles initial delay
  periodSeconds: 10        # Check every 10 seconds
  timeoutSeconds: 3-5      # Generous timeout for slow responses
  failureThreshold: 3      # Tolerance: 30s of failures before restart
```

**Critical components without startup probe** (legacy):
- Use `initialDelaySeconds: 15-30` to prevent false positives
- Example: Vault with unseal process

### 3. Readiness Probe Pattern

**Purpose**: Control traffic routing - mark pod ready only when it can serve requests

**Key characteristics**:
- Can be stricter than liveness (accepts fewer states)
- Should check downstream dependencies if critical
- Fast period for responsive load balancing

**Standard configuration**:
```yaml
readinessProbe:
  httpGet:
    path: /readyz  # or /ready
    port: 8081
  initialDelaySeconds: 0   # Startup probe handles initial delay
  periodSeconds: 5-10      # Frequent checks for LB responsiveness
  timeoutSeconds: 3-5
  failureThreshold: 3-6    # More tolerance than liveness
  successThreshold: 1      # Single success = ready
```

## Component-Specific Patterns

### Java Applications (SonarQube, etc.)

**Challenge**: Slow JVM startup, potential DB migrations

**Strategy**:
```yaml
startupProbe:
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 18    # 30s + 180s = 210s total
  timeoutSeconds: 3       # Exec commands need more time

livenessProbe:
  initialDelaySeconds: 0  # Startup handles slow boot
  periodSeconds: 30       # Less frequent for heavy apps
  timeoutSeconds: 3

readinessProbe:
  initialDelaySeconds: 0
  periodSeconds: 10       # Responsive to status changes
  timeoutSeconds: 3
```

**Special considerations**:
- Use exec probes to check application-specific APIs
- Accept intermediate states in readiness (e.g., DB_MIGRATION_RUNNING)
- Liveness should check system passcode endpoints

### Go Operators (External Secrets, Cert-Manager)

**Challenge**: Fast startup, but webhook registration takes time

**Strategy**:
```yaml
# For webhook components
readinessProbe:
  initialDelaySeconds: 5-10  # Wait for webhook registration
  periodSeconds: 5
  failureThreshold: 3-6      # Higher for admission controllers

livenessProbe:
  initialDelaySeconds: 0-5
  periodSeconds: 10
  failureThreshold: 3
```

**Special considerations**:
- Never use `initialDelaySeconds: 0` for webhooks (cert-manager learned this)
- 5-10s delay ensures webhook server is listening
- Kyverno uses startup probe with high failureThreshold (40) for this reason

### Stateful Applications (Vault, Databases)

**Challenge**: Initialization, unsealing, or recovery processes

**Strategy**:
```yaml
livenessProbe:
  enabled: true  # CRITICAL: Must enable to prevent silent hangs
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3
  execCommand: []  # Use HTTP path or custom exec

readinessProbe:
  enabled: true
  path: "/health?standbyok=true&sealedcode=204&uninitcode=204"  # Accept initialization states
  periodSeconds: 5
  failureThreshold: 3
```

**Special considerations**:
- Readiness must accept "not yet ready" states (sealed, uninitialized)
- Liveness checks basic process responsiveness only
- Never disable liveness on critical infrastructure

### DaemonSets (Fluent-bit, Node Exporters)

**Challenge**: Must start quickly, run on every node

**Strategy**:
```yaml
startupProbe:
  initialDelaySeconds: 5   # Minimal - fast startup expected
  periodSeconds: 5
  failureThreshold: 10     # 5s + 50s = 55s max

livenessProbe:
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 3
```

**Special considerations**:
- Keep startup window tight (< 60s)
- Log collectors should be ready before workloads start
- Use hostPath volumes - may delay startup on slow disks

### Single Binary Deployments (Loki SingleBinary)

**Challenge**: One process handles multiple concerns

**Strategy**:
```yaml
startupProbe:
  path: /ready  # Single endpoint for all subsystems
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 12  # 10s + 60s = 70s

livenessProbe:
  path: /ready  # Same endpoint OK for monolith
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  path: /ready
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 3
```

**Special considerations**:
- Can reuse same endpoint for all probes
- Ensure /ready checks all critical subsystems
- Tight timeouts (1s) acceptable for simple endpoints

## Endpoint Standards

### HTTP Probe Endpoints

**Standard paths** (Kubernetes convention):
- `/livez` - Liveness (process alive, not deadlocked)
- `/readyz` - Readiness (ready to serve traffic)
- `/healthz` - Generic health (deprecated, use specific endpoints)

**Legacy/custom paths**:
- `/health` - Common in older apps
- `/api/v1/health` - API-specific health
- `/ready` - Simplified readiness

**Status codes**:
- `200-399`: Healthy/Ready
- `400-599`: Unhealthy/Not Ready
- Custom codes: Configure via `sealedcode`, `uninitcode` params (Vault pattern)

### Exec Probe Commands

**Standard pattern**:
```yaml
exec:
  command:
    - sh
    - -c
    - |
      #!/bin/bash
      # Check condition
      if [[ condition ]]; then
        exit 0  # Healthy
      fi
      exit 1    # Unhealthy
```

**Best practices**:
- Use `sh -c` for multi-line scripts
- Always exit explicitly (0 = success, 1 = failure)
- Keep scripts fast (< timeoutSeconds)
- Avoid external dependencies (curl, wget should be in image)

## Timing Guidelines

### Initial Delay Recommendations

| Component Type | With Startup Probe | Without Startup Probe |
|----------------|--------------------|-----------------------|
| Go binary | 0s | 5-10s |
| Java app | 0s | 60s+ |
| Python app | 0s | 15-30s |
| Database/Stateful | 0s | 30-60s |
| Webhook/Admission | 0s | 10-15s (NEVER 0!) |

### Period Recommendations

| Probe Type | Standard | High Availability | Resource Constrained |
|------------|----------|-------------------|----------------------|
| Startup | 5-10s | 5s | 10s |
| Liveness | 10s | 5s | 30s |
| Readiness | 5-10s | 5s | 10s |

### Timeout Recommendations

| Probe Mechanism | Standard | Complex Check | Simple Check |
|-----------------|----------|---------------|--------------|
| HTTP GET | 3-5s | 5s | 1s |
| Exec command | 3s | 5s | 1s |
| TCP socket | 1s | 1s | 1s |

### Failure Threshold Recommendations

| Probe Type | Standard | Tolerance High | Tolerance Low |
|------------|----------|----------------|---------------|
| Startup | 12-18 | 20-40 (Kyverno) | 10 |
| Liveness | 3 | 6 | 2 |
| Readiness | 3 | 6 | 2 |

## Anti-Patterns to Avoid

### ❌ No Liveness Probe on Critical Infrastructure

**Problem**: Silent hangs never recover
```yaml
# BAD - Vault without liveness
livenessProbe:
  enabled: false
```

**Impact**: If Vault deadlocks, External Secrets stops syncing secrets silently

**Solution**: Always enable liveness on infrastructure components

### ❌ initialDelaySeconds: 0 on Webhooks

**Problem**: Webhook server not ready when probe starts
```yaml
# BAD - Cert-manager webhook
livenessProbe:
  initialDelaySeconds: 0  # Webhook registration takes time!
```

**Impact**: False negatives, pod restart loops

**Solution**: Minimum 5s delay, or use startup probe

### ❌ Timeout Too Aggressive for Exec Commands

**Problem**: Complex scripts get killed mid-execution
```yaml
# BAD - SonarQube with 1s timeout
livenessProbe:
  exec:
    command: [sh, -c, "curl ... | grep ..."]  # May take >1s
  timeoutSeconds: 1
```

**Impact**: Healthy pods marked unhealthy, unnecessary restarts

**Solution**: 3s minimum for exec, 5s for complex checks

### ❌ Same High initialDelay for All Probes

**Problem**: Slow startup even with startup probe
```yaml
# BAD - Redundant delays
startupProbe:
  initialDelaySeconds: 30
  failureThreshold: 18
livenessProbe:
  initialDelaySeconds: 60  # Unnecessary!
readinessProbe:
  initialDelaySeconds: 60  # Unnecessary!
```

**Impact**: 60s wasted waiting for liveness/readiness after startup succeeds

**Solution**: Use initialDelaySeconds: 0 when startup probe exists

### ❌ No Startup Probe for Variable Boot Times

**Problem**: Liveness must accommodate worst-case startup
```yaml
# BAD - SonarQube without startup probe
livenessProbe:
  initialDelaySeconds: 180  # Prevents any liveness checks for 3 minutes!
  periodSeconds: 30
```

**Impact**: Deadlocks after startup won't be detected for minutes

**Solution**: Add startup probe, reduce liveness delay to 0

## Dependency-Aware Probe Configuration

### Sync-Wave Integration

Probes must align with ArgoCD sync-wave strategy:

**Wave 0: Namespaces**
- No probes (configuration resources)

**Wave 1: Kyverno (Admission Webhook)**
```yaml
# Must be ready before wave 2 starts
startupProbe:
  initialDelaySeconds: 15
  failureThreshold: 40  # 215s max - webhook registration critical
readinessProbe:
  initialDelaySeconds: 10  # Wait for webhook server
  failureThreshold: 6
```

**Wave 2: Trivy (Depends on Kyverno)**
```yaml
# Kyverno startup probe ensures webhook is ready before Trivy creates jobs
# No special probe config needed - dependency handled by sync-wave
```

### Infrastructure Chain (IT/)

Deployed manually BEFORE ArgoCD, order matters:

**Vault** → **External Secrets** → **Cert-Manager** → **ArgoCD**

```yaml
# Vault - Foundation, must be stable
livenessProbe:
  enabled: true  # CRITICAL
  initialDelaySeconds: 15
  
# External Secrets - Depends on Vault
livenessProbe:
  enabled: true  # CRITICAL
  initialDelaySeconds: 10
  
# Cert-Manager Webhook - Others depend on certs
livenessProbe:
  initialDelaySeconds: 5  # NEVER 0
readinessProbe:
  initialDelaySeconds: 5  # NEVER 0
```

## Testing Health Probes

### Manual Validation

```bash
# Test HTTP probe endpoint
kubectl exec -n <namespace> <pod> -- wget -qO- http://localhost:8081/readyz

# Test exec probe command
kubectl exec -n <namespace> <pod> -- sh -c '<command from probe>'

# Watch probe failures in real-time
kubectl get events -n <namespace> --field-selector reason=Unhealthy --watch

# Check restart counts (indicates probe failures)
kubectl get pods -n <namespace> -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount
```

### Simulating Failures

```bash
# Crash process (triggers liveness)
kubectl exec -n <namespace> <pod> -- kill 1

# Block health endpoint (triggers both liveness and readiness)
kubectl exec -n <namespace> <pod> -- iptables -A OUTPUT -p tcp --dport 8081 -j DROP

# Slow down response (test timeouts)
kubectl exec -n <namespace> <pod> -- tc qdisc add dev eth0 root netem delay 10s
```

### Metrics to Monitor

```promql
# Probe failure rate
rate(prober_probe_failed_total[5m])

# Pod restarts (indicates liveness failures)
rate(kube_pod_container_status_restarts_total[1h]) > 3

# Pods not ready (indicates readiness failures)
kube_pod_status_phase{phase="Pending"} > 0
```

## Migration Guide

### Adding Startup Probe to Existing Component

**Before**:
```yaml
livenessProbe:
  initialDelaySeconds: 60
  periodSeconds: 10
readinessProbe:
  initialDelaySeconds: 60
  periodSeconds: 30
```

**After**:
```yaml
startupProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 10  # 30s + 100s = 130s total
  timeoutSeconds: 3
  
livenessProbe:
  httpGet:
    path: /livez
    port: http
  initialDelaySeconds: 0  # Reduced from 60s
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
  
readinessProbe:
  httpGet:
    path: /readyz
    port: http
  initialDelaySeconds: 0  # Reduced from 60s
  periodSeconds: 10        # Reduced from 30s for responsiveness
  timeoutSeconds: 3
  failureThreshold: 3
```

**Impact**:
- Startup window same or better: 130s vs 60s (more tolerance)
- Post-startup health checks much faster: 0s vs 60s delay
- Failures detected in 30s vs 100s+ after startup

### Enabling Liveness on Infrastructure

**Before**:
```yaml
# Vault
livenessProbe:
  enabled: false  # Disabled due to unseal complexity
```

**After**:
```yaml
livenessProbe:
  enabled: true
  initialDelaySeconds: 15  # After unseal completes
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
  # Uses default HTTP path: /v1/sys/health?standbyok=true
```

**Deployment**:
1. Update values in Git
2. Apply via Helm (IT/) or ArgoCD (K8s/)
3. Monitor pods during rollout: `kubectl get pods -w`
4. Verify no restart loops in first 5 minutes
5. Check events: `kubectl get events --field-selector reason=Unhealthy`

## Reference Implementations

### Vault (Stateful, Critical Infrastructure)

Location: `IT/vault/values.yaml:58-85`

```yaml
livenessProbe:
  enabled: true
  failureThreshold: 3
  initialDelaySeconds: 15
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 3
  execCommand: []  # Uses default HTTP path

readinessProbe:
  enabled: true
  failureThreshold: 3
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
```

**Key points**:
- Readiness accepts sealed/uninitialized states (required for bootstrap)
- Liveness enabled to prevent silent hangs
- Conservative delays for stateful recovery

### Kyverno (Admission Webhook, Sync-Wave 1)

Location: `Policies/kyverno/values.yaml:37-71`

```yaml
livenessProbe:
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 1
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 10  # CRITICAL: Webhook registration
  periodSeconds: 5
  timeoutSeconds: 1
  successThreshold: 1
  failureThreshold: 6

startupProbe:
  initialDelaySeconds: 15
  periodSeconds: 5
  timeoutSeconds: 1
  successThreshold: 1
  failureThreshold: 40  # 15s + 200s = 215s max
```

**Key points**:
- Startup probe with very high threshold prevents race with Trivy (wave 2)
- Readiness has 10s delay for webhook server initialization
- ArgoCD won't proceed to wave 2 until Kyverno is ready

### SonarQube (Java, Database Migrations)

Location: `K8s/cicd/sonarqube/values.yaml:28-80`

```yaml
startupProbe:
  exec:
    command:
      - sh
      - -c
      - >
        if curl -s -f http://localhost:9000/api/system/status | grep -q -e '"status":"UP"' -e '"status":"DB_MIGRATION_NEEDED"' -e '"status":"DB_MIGRATION_RUNNING"';
        then exit 0;
        fi;
        exit 1
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 18  # 30s + 180s = 210s total
  timeoutSeconds: 3

livenessProbe:
  exec:
    command:
      - sh
      - -c
      - 'wget --no-proxy --quiet -O /dev/null --timeout=3 --header="X-Sonar-Passcode: $SONAR_WEB_SYSTEMPASSCODE" "http://localhost:9000/api/system/liveness"'
  initialDelaySeconds: 0
  periodSeconds: 30
  failureThreshold: 6
  timeoutSeconds: 3

readinessProbe:
  exec:
    command:
      - sh
      - -c
      - >
        if curl -s -f http://localhost:9000/api/system/status | grep -q -e '"status":"UP"' -e '"status":"DB_MIGRATION_NEEDED"' -e '"status":"DB_MIGRATION_RUNNING"';
        then exit 0;
        fi;
        exit 1
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 6
  timeoutSeconds: 3
```

**Key points**:
- Exec probes to check application-specific APIs
- Readiness accepts intermediate states (DB_MIGRATION_RUNNING)
- Liveness uses authenticated endpoint with passcode
- Startup handles 210s window for migrations, then aggressive probes

### External Secrets (Go Operator, Critical)

Location: `IT/external-secrets/values.yaml:49-68`

```yaml
livenessProbe:
  enabled: true
  spec:
    httpGet:
      port: 8081
      path: /healthz
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3

readinessProbe:
  enabled: true
  spec:
    httpGet:
      port: 8081
      path: /readyz
    initialDelaySeconds: 20
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
```

**Key points**:
- Liveness enabled (critical infrastructure - prevents silent hangs)
- Separate /healthz and /readyz endpoints
- Conservative delays for operator initialization

## Troubleshooting Guide

### Pod in CrashLoopBackOff

**Symptom**: Pod restarts repeatedly, status shows CrashLoopBackOff

**Diagnosis**:
```bash
# Check events for probe failures
kubectl describe pod <pod-name> -n <namespace>

# Look for "Liveness probe failed" or "Readiness probe failed"
kubectl get events -n <namespace> --field-selector involvedObject.name=<pod-name>

# Check if application is actually starting
kubectl logs <pod-name> -n <namespace> --previous
```

**Common causes**:
1. **Liveness too aggressive**: `initialDelaySeconds` too short
   - Solution: Increase initialDelaySeconds or add startup probe
2. **Wrong health endpoint**: Path or port misconfigured
   - Solution: Verify endpoint manually with kubectl exec
3. **Application crash**: Real failure, not probe issue
   - Solution: Fix application, not probe

### Pod Stuck in "Not Ready"

**Symptom**: Pod running but never enters Ready state

**Diagnosis**:
```bash
# Check readiness probe status
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 Readiness

# Test readiness endpoint manually
kubectl exec <pod-name> -n <namespace> -- curl -f http://localhost:8081/readyz
```

**Common causes**:
1. **Dependency not ready**: Waiting for database, external service
   - Solution: Check dependency chain, increase failureThreshold
2. **Wrong success criteria**: Probe expects different response
   - Solution: Align probe with application's actual ready state
3. **Webhook not registered**: Admission controllers need registration time
   - Solution: Add 5-10s initialDelaySeconds (never 0)

### Probes Working But App Not Healthy

**Symptom**: Probes pass but application returns errors

**Root cause**: Probes check wrong aspect of health

**Solutions**:
1. **Liveness too simple**: Only checks process alive, not functionality
   - Fix: Check critical subsystems (database connection, cache)
2. **Readiness doesn't check dependencies**: Reports ready without downstream services
   - Fix: Add dependency checks to readiness probe
3. **Probe bypasses authentication**: Health endpoint not protected like real traffic
   - Fix: Use authenticated endpoints (SonarQube pattern with passcode)

## Future Considerations

### gRPC Probes (Kubernetes 1.24+)

When available, prefer gRPC probes for better performance:

```yaml
livenessProbe:
  grpc:
    port: 9090
    service: health  # Optional, defaults to ""
  initialDelaySeconds: 0
  periodSeconds: 10
```

**Benefits**:
- Native protocol support (no HTTP overhead)
- Standard health checking protocol
- Better for microservices

### Startup Probe with gRPC

```yaml
startupProbe:
  grpc:
    port: 9090
    service: startup
  failureThreshold: 30
  periodSeconds: 10
```

### Probe-Level Metrics

Export custom metrics from health endpoints:

```yaml
# Readiness probe that also exposes metrics
readinessProbe:
  httpGet:
    path: /ready?metrics=true
    port: 8081
```

Application returns both status + metrics in response body for observability.

## Summary Checklist

When adding health probes to a new component:

- [ ] Component has startup probe if boot time > 15s or variable
- [ ] Liveness probe enabled for all infrastructure (Vault, operators, etc.)
- [ ] Webhook components have initialDelaySeconds >= 5s (NEVER 0)
- [ ] initialDelaySeconds: 0 for liveness/readiness when startup probe exists
- [ ] Timeout >= 3s for exec probes, >= 1s for HTTP
- [ ] failureThreshold provides reasonable tolerance (3 for liveness, 3-6 for readiness)
- [ ] Readiness probe more frequent than liveness (period: 5-10s vs 10-30s)
- [ ] Exec commands tested manually with kubectl exec
- [ ] HTTP endpoints return correct status codes (200-399 = healthy)
- [ ] Stateful apps accept initialization states in readiness (sealed, migrating, etc.)
- [ ] Sync-wave dependencies reflected in probe timing (Kyverno before Trivy)
- [ ] YAML validated with yamllint
- [ ] Deployment tested in dev environment first
- [ ] No restart loops observed in first 10 minutes
- [ ] Events checked for probe failures

## Related Documentation

- [ArgoCD Sync-Wave Strategy](argocd-sync-wave-strategy.md) - Deployment ordering
- [Project Overview](project_overview.md) - Component architecture
- [Codebase Structure](codebase_structure.md) - File locations

## Changelog

- 2025-01-22: Initial documentation based on comprehensive probe audit
  - Standardized probe configurations across all components
  - Added startup probes to SonarQube, Loki, Fluent-bit
  - Enabled liveness probes on Vault and External Secrets
  - Reduced total startup time by 120 seconds
  - Established component-specific patterns and anti-patterns
