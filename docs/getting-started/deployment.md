# Getting Started - Deployment

This guide provides detailed information about the deployment process and what happens during platform setup.

## Deployment Process

The `task deploy` command executes the following phases:

### Phase 1: Bootstrap Cluster
1. **Create K3d Cluster**: Creates a 3-node k3d cluster with optimized configuration
2. **Apply Namespaces**: Creates all required namespaces for different components
3. **Bootstrap Infrastructure**: Deploys core infrastructure components
4. **Deploy Cilium**: Sets up eBPF-based networking and service mesh

### Phase 2: Secrets & Certificates Management
1. **Deploy Cert-Manager**: Sets up certificate automation system
2. **Deploy Vault**: Configures secrets management backend
3. **Deploy External Secrets**: Establishes synchronization between Vault and Kubernetes

### Phase 3: GitOps Engine
1. **Deploy ArgoCD**: Sets up the GitOps engine that will manage the rest of the platform

### Phase 4: Gateway and Policy
1. **Deploy Gateway**: Configures ingress for external access
2. **Deploy Policy Engine**: Sets up Kyverno for policy enforcement

### Phase 5: Application Stacks
1. **Deploy Observability Stack**: Prometheus, Grafana, Loki, and Fluent-bit
2. **Deploy CI/CD Stack**: Argo Workflows and SonarQube
3. **Deploy Security Stack**: Trivy for vulnerability scanning

## Deployment Customization

You can customize the deployment using environment variables:

```bash
# Increase timeout for slower systems
task deploy KUBECTL_TIMEOUT=600s

# Use different k3d configuration (without registry cache)
task deploy:nocache
```

## Resource Allocation

The platform intelligently allocates resources using PriorityClasses:
- `platform-infrastructure`: For core infrastructure components
- `platform-observability`: For monitoring and observability tools
- `platform-cicd`: For CI/CD workloads
- `platform-security`: For security tools
- `platform-policy`: For policy enforcement
- `platform-dashboards`: For dashboard tools

## Post-Deployment

After successful deployment:
1. All components will be visible in ArgoCD
2. Services will be accessible via the nip.io addresses
3. Default credentials will be available in Vault
4. Monitoring dashboards will start showing metrics
5. Security scanning will begin automatically

## Troubleshooting

If you encounter issues during deployment:
1. Check the [Troubleshooting Reference](../reference/troubleshooting.md)
2. Verify your prerequisites are met
3. Ensure Docker is running and not rate-limited
4. Check that sufficient resources are available on your system