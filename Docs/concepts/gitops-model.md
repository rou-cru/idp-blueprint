# GitOps Model

IDP Blueprint is GitOps‑first with ArgoCD and ApplicationSets. The repository structure and tasks are designed so that adding or removing a stack component is a simple Git change.

## Layers: Bootstrap vs GitOps

- Bootstrap (IT/): one‑time installation of cluster prerequisites and control planes (Cilium, cert‑manager, Vault, External Secrets, ArgoCD, Gateway). See `task bootstrap:*` calls wired into `task deploy`.
- GitOps (K8s/): ArgoCD ApplicationSets watch `K8s/*` directories and generate Applications for each stack component (observability, CI/CD, security, policies).

See also the [Bootstrap Process](../architecture/bootstrap.md) and the GitOps visuals in [Visual Map](../architecture/visual.md).

## AppProjects: guardrails per stack

AppProjects scope sources and destinations:

- Files: `IT/argocd/appproject-*.yaml` applied during `task bootstrap:argocd:deploy`
- They set `spec.sourceRepos: ${REPO_URL}` and `destinations` per namespace

Example: `IT/argocd/appproject-observability.yaml` allows deploying to `namespace: observability` on the in‑cluster server.

## ApplicationSets: directory→Application mapping

ApplicationSets generate Applications from folders. The `stacks:deploy` task applies them with variables substituted via `envsubst`:

```bash
envsubst < applicationset-observability.yaml | kubectl apply -f -
```

Example (excerpt from `K8s/observability/applicationset-observability.yaml`):

```yaml
spec:
  generators:
    - git:
        repoURL: ${REPO_URL}
        revision: ${TARGET_REVISION}
        directories:
          - path: K8s/observability/*
  template:
    metadata:
      name: 'observability-{{path.basename}}'
    spec:
      project: observability
      source:
        repoURL: ${REPO_URL}
        targetRevision: ${TARGET_REVISION}
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: observability
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - ServerSideApply=true
          - PruneLast=true
          - ApplyOutOfSyncOnly=true
```

Other stacks follow the same pattern:

- `K8s/cicd/applicationset-cicd.yaml` (excludes `jenkins.disabled`)
- `K8s/security/applicationset-security.yaml`

## GitOps Flow

```d2
direction: right

Git: {
  label: "Git Repository\nREPO_URL @ TARGET_REVISION"
  REPO: "REPO_URL @ TARGET_REVISION"
  OBS: "K8s/observability/*"
  CICD: "K8s/cicd/*"
  SEC: "K8s/security/*"
}

ArgoCD: {
  AP1: "AppProject: observability"
  AP2: "AppProject: cicd"
  AP3: "AppProject: security"
  AS1: "ApplicationSet: observability"
  AS2: "ApplicationSet: cicd"
  AS3: "ApplicationSet: security"
}

Cluster: {
  NSO: "ns: observability"
  NSC: "ns: cicd"
  NSS: "ns: security"
  APPs: "Applications + Workloads"
}

Git.REPO -> ArgoCD.AS1
Git.REPO -> ArgoCD.AS2
Git.REPO -> ArgoCD.AS3
ArgoCD.AS1 -> Git.OBS: "dir generator"
ArgoCD.AS2 -> Git.CICD: "dir generator"
ArgoCD.AS3 -> Git.SEC: "dir generator"
ArgoCD.AS1 -> Cluster.NSO: "template"
ArgoCD.AS2 -> Cluster.NSC: "template"
ArgoCD.AS3 -> Cluster.NSS: "template"
ArgoCD.AS1 -> Cluster.APPs
ArgoCD.AS2 -> Cluster.APPs
ArgoCD.AS3 -> Cluster.APPs
ArgoCD.AP1 -> ArgoCD.AS1: "scopes"
ArgoCD.AP2 -> ArgoCD.AS2: "scopes"
ArgoCD.AP3 -> ArgoCD.AS3: "scopes"
```

## Variables: repo and revision

- `REPO_URL` and `TARGET_REVISION` are read from `config.toml` by tasks (preferred),
  and fall back to the current git remote/branch if empty. Tasks substitute them
  via `envsubst` when applying manifests.

!!! note
    Use `config.toml` as the canonical place to set configuration (repo, branch,
    network, versions, passwords). Only use ad‑hoc environment overrides for
    temporary testing.

## Sync policy and drift

- Automated prune + self‑heal keeps the cluster aligned with Git.
- `ServerSideApply` and `ApplyOutOfSyncOnly` reduce noisy updates.
- Webhook `caBundle` fields are ignored in diffs to avoid perpetual drift (see `ignoreDifferences` in observability ApplicationSet).

## Add, change, remove a component

- Add: create a new folder under the stack (`K8s/observability/<name>`) with a Kustomize overlay or Helm values; commit and push.
- Change: edit values/overlays and push; ArgoCD reconciles.
- Remove: delete the folder; ArgoCD prunes the Application on next sync.

## Policies and secrets in the loop

- Kyverno enforces policies at admission; violations appear in Policy Reporter.
- External Secrets Operator authenticates to Vault (configured during bootstrap) and syncs Kubernetes Secrets needed by components (e.g., ArgoCD admin password).
