# CI/CD Stack (Argo Workflows + SonarQube)

The `K8s/cicd/` directory hosts everything developers need to run workflows, quality scans, and build-time policies inside the IDP.

## Components

| Component | Path | Highlights |
| --- | --- | --- |
| Argo Workflows | `K8s/cicd/argo-workflows/` | Workflow controller + server with metrics + RBAC locked to `cicd` namespace. |
| Governance manifests | `K8s/cicd/governance/` | ResourceQuota + LimitRange to keep demo workloads lightweight. |
| SonarQube | `K8s/cicd/sonarqube/` | Community edition with Vault-managed admin password + monitoring passcode. |

## Workflow Execution Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Repo (Workflow YAML)
    participant ArgoCLI as Argo CLI / UI
    participant Controller as Workflow Controller
    participant Pods as Workflow Pods
    participant Sonar as SonarQube

    Dev->>Git: 1. Commit workflow template
    Dev->>ArgoCLI: 2. Submit workflow (referencing Git artifact)
    ArgoCLI->>Controller: 3. Create Workflow CR
    Controller->>Pods: 4. Launch pods using cicd-execution priority class
    Pods->>Sonar: 5. Optional quality gate step via webhook/token
    Pods-->>Controller: 6. Emit results, artifacts optional
    Controller-->>Dev: 7. Surface status via UI/CLI/metrics
```

## Secrets & Credentials

- **Argo Workflows** authenticates to Vault-backed secrets via External Secrets (see `argo-workflows-values.yaml` and `IT/external-secrets/`).
- **SonarQube admin & monitoring tokens** come from Vault and are injected by Helm after ESO syncs the secret.
- Additional CI secrets follow the same pattern: define them in Vault, sync via `ExternalSecret`, mount as env vars in workflow pods.

## Observability Hooks

- Workflow controller metrics are scraped by Prometheus via `ServiceMonitor` and surfaced in Grafana.
- Argo emits Kubernetes events; Fluent-bit ships them to Loki so you can tail workflow logs centrally.
- SonarQube exposes readiness/liveness probes along with JVM metrics—enable dashboards for quality gates and scan times.

## Extending the Stack

1. **Add Workflows** – store reusable templates under `K8s/cicd/argo-workflows/templates/` (or similar), include them via ConfigMaps, and reference them in Workflow manifests.
2. **Add Build Tools** – create subdirectories (e.g., `kaniko/`, `tekton/`) and update `applicationset-cicd.yaml` so ArgoCD auto-syncs them.
3. **Expose CI Services** – enable Ingress/Gateway entries in values files to expose SonarQube or Argo Workflows UI via the platform Gateway.
4. **Integrate pipelines** – Use Argo Events or GitHub webhooks (future work) to trigger workflows automatically.

## Example: Quality Gate Workflow

```mermaid
flowchart LR
    Code[Source Repo]
    Build[Build & Test Step]
    Scan[SonarQube Scan]
    Gate{Quality Gate}
    Deploy[GitOps Merge]

    Code --> Build --> Scan --> Gate
    Gate -- pass --> Deploy
    Gate -- fail --> Code
```

In Argo Workflows, this translates to a DAG with `build` → `sonarqube-scan` → `quality-gate`. The scan step reaches out to SonarQube using the Vault-provisioned monitoring token.
