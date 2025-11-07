# Resource Requirements

Understanding the resource requirements for the IDP Blueprint platform is crucial for proper planning and operation.

## Minimum System Requirements

### Hardware
- **CPU**: 4 cores minimum (6+ recommended)
- **Memory**: 8GB RAM minimum (12GB+ recommended)
- **Storage**: 20GB available disk space
- **Network**: Stable internet connection for pulling images

### Software
- Docker with authenticated access to Docker Hub
- Git version 2.0 or higher
- Visual Studio Code with Dev Containers extension

## Platform Resource Footprint

### Theoretical Minimum (Total Requests)

| Resource | Total Requested |
|----------|----------------:|
| **CPU** | **~3.5 cores** |
| **Memory** | **~5.4 GiB** |

### Theoretical Maximum (Total Limits)

| Resource | Total Limited |
|----------|---------------:|
| **CPU** | **~8.9 cores** |
| **Memory** | **~11 GiB** |

## Component Resource Requirements

### Infrastructure Layer (Node 2)
- **Cilium**: 0.5-1.0 cores CPU, 0.5-1.0 GiB RAM
- **Cert-Manager**: 0.3-0.5 cores CPU, 0.2-0.5 GiB RAM
- **Vault**: 0.5-1.0 cores CPU, 0.3-0.5 GiB RAM
- **External Secrets Operator**: 0.2-0.3 cores CPU, 0.1-0.3 GiB RAM
- **ArgoCD**: 1.0-1.5 cores CPU, 0.8-1.2 GiB RAM

### GitOps Workloads (Node 3)
- **Kyverno**: 0.5-1.0 cores CPU, 0.5-1.0 GiB RAM
- **Prometheus**: 0.5-1.0 cores CPU, 1.0-2.0 GiB RAM
- **Grafana**: 0.1-0.3 cores CPU, 0.1-0.3 GiB RAM
- **Loki**: 0.5-1.0 cores CPU, 0.5-1.5 GiB RAM
- **Fluent-bit**: 0.2-0.5 cores CPU, 0.2-0.5 GiB RAM
- **Argo Workflows**: 0.5-1.0 cores CPU, 0.5-1.0 GiB RAM
- **SonarQube**: 1.0-2.0 cores CPU, 1.0-2.0 GiB RAM
- **Trivy**: 0.5-1.0 cores CPU, 0.5-1.0 GiB RAM

## Memory Optimization Tips

### For Limited Resources
1. **Scale down non-critical components** during development
2. **Adjust resource limits** in the Helm value files
3. **Use node selectors** to distribute workloads
4. **Consider disabling** non-essential components during development

### Priority Classes Used
The platform uses several priority classes to ensure critical components are scheduled:
- `platform-infrastructure`: Highest priority for core components
- `platform-observability`: For monitoring tools
- `platform-cicd`: For CI/CD workloads
- `platform-security`: For security tools
- `platform-policy`: For policy enforcement

## Storage Requirements

### Kubernetes Volumes
- **Vault Data**: 1Gi persistent storage
- **Prometheus Data**: 10Gi persistent storage
- **Loki Data**: 2Gi persistent storage
- **SonarQube Data**: 2Gi persistent storage
- **Fluent-bit State**: Small persistent storage for log states

### Docker Images
- Initial download: ~8-10GB depending on available cache
- Local registry cache: ~5-8GB after deployment
- Temporary build artifacts: ~1-2GB

## Performance Considerations

### For Development
- The platform is optimized for resource efficiency
- Components have been tuned for local development
- Non-essential features may be disabled by default

### For Production-like Testing
- Resource requirements may be increased
- Additional replicas may be configured
- Persistent storage may be expanded

> **Note**: These values exclude k3d control plane overhead and OS requirements. Real-world usage may vary based on actual workloads.