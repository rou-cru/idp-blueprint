# Merge Conflict Resolution Strategy: `main` as Base (PR #77)

## Strategic Pivot

**Original Strategy:** Merge `main` → `update-docs` (hybrid approach)
**New Strategy:** Keep `main` as base, cherry-pick valuable changes from `update-docs`

**Rationale:** `main` contains 1500+ lines of critical architecture documentation and operational fixes that cannot be safely merged into the restructured `update-docs`. Inverting the strategy minimizes risk.

## Overview
This document analyzes what can be rescued from `update-docs` when `main` is kept as the foundation. Changes are classified by integration complexity and value.

## Rescuable Changes from `update-docs` (Classified)

### Category 1: Directly Rescuable (Low Risk, High Value)

These changes can be cherry-picked or copied directly onto `main` with minimal/no conflict:

#### 1.1 GitHub Actions Workflows (Complete Replacement)
**Location:** `.github/workflows/`, `.github/dependabot.yml`, `.github/labeler.yml`, `.github/pull_request_template.md`, Issue templates

**Value:** Production-grade CI/CD pipeline with:
- **CI improvements:**
  - Path-based change detection (docs-only vs full build)
  - Concurrency control (cancel-in-progress)
  - Matrix builds for docker targets (dev/minimal/ops/portal)
  - Quality gates: lint, security scans, validations
  - Conditional Helm docs generation on `values.yaml` changes
  - PR-only execution (not on push to main)
- **Auto-merge workflow** with CodeRabbit integration
- **Docs deployment** workflow
- **Auto-labeler** for PRs
- **Stale issue management**

**Action:** Copy entire `.github/` directory from `update-docs` → `main`

**Risk:** None. `main` has minimal `.github/` content.

---

#### 1.2 Configuration Management (`config.toml`)
**Location:** `config.toml` (root)

**Value:** Centralized configuration for:
- Cluster settings (name, network, nodeports)
- Feature fuses (policies, security, observability, cicd, backstage, prod)
- Component versions (Cilium, Cert-Manager, Vault, etc.)
- Operational timeouts
- Git repository settings
- ArgoCD sync configuration
- Registry credentials

**Action:** Copy `config.toml` from `update-docs` → `main`

**Risk:** Low. File doesn't exist in `main`.

---

#### 1.3 Docker Bake Configuration Enhancements
**Location:** `docker-bake.hcl`

**Changes:**
- Adds `ops` target (cluster utility jobs)
- Adds `dev-portal` target (Backstage backend)
- Proper variant tagging (`:minimal`, `:ops`, `:latest`)
- Separate release targets for each variant

**Action:** Apply diff from `update-docs` → `main`

**Risk:** Low. Changes are additive.

---

#### 1.4 Backstage Developer Portal (Complete UI/Backend)
**Location:** `UI/packages/app/*`, `UI/packages/backend/*`

**Value:** Full Backstage implementation:
- Frontend: React app with Primer theme, catalog, search
- Backend: Node.js server with Dockerfile
- E2E tests with Playwright
- Complete package configuration

**Action:** Copy entire `UI/packages/` directory from `update-docs` → `main`

**Risk:** None. Directory doesn't exist in `main`.

---

#### 1.5 Load Testing Script
**Location:** `load-test-gateway.js` (root)

**Value:** K6-compatible script for Gateway API load testing

**Action:** Copy file from `update-docs` → `main`

**Risk:** None.

---

### Category 2: Indirectly Rescuable (Requires Adaptation)

These changes have valuable intent but conflict with `main` or require manual integration:

#### 2.1 Taskfile UX Improvements (`internal` flags)
**Location:** `Taskfile.yaml`, `Task/*.yaml` (9 files)

**Value in `update-docs`:**
- Adds `internal: true` to ~30 tasks (cleaner `task --list` output)
- Adds global `dotenv: [".env"]` for environment loading
- Refactored task structure (e.g., `deploy-core` as internal logic)

**Conflict:** `main` has new tasks and operational logic (294 lines in `bootstrap.yaml` alone)

**Rescue Strategy:**
1. **Manual review:** Identify which tasks in `main` should be marked `internal: true`
2. **Apply selectively:** Add `internal` flags to low-level tasks (apply-*, preload-*, etc.)
3. **Keep `main` logic:** Do NOT alter `cmds:` or operational steps
4. **Add `dotenv`:** Safe to add global dotenv declaration

**Risk:** Medium. Requires line-by-line review to avoid breaking functionality.

**Estimated Effort:** 2-3 hours manual work across 9 files.

---

#### 2.2 Documentation Reorganization (concepts → implementation)
**Location:** `Docs/src/content/docs/`

**Value in `update-docs`:**
- Renamed `concepts/` → `implementation/` (semantic clarity)
- Moved `components/` → `implementation/components/` (logical grouping)

**Conflict:** `main` added 1500+ lines to `architecture/` and created `architecture/observability.mdx` (which replaces deleted `concepts/observability.mdx`)

**Rescue Strategy:**
1. **Defer restructure:** Keep `main` structure as-is
2. **Track as future work:** Create issue for "Reorganize docs structure" referencing `update-docs` branch
3. **Preserve intent:** Document that `concepts/` should become `implementation/` in future refactor

**Risk:** High if attempted now. Low if deferred.

**Recommendation:** **Do not rescue.** Architecture work in `main` supersedes this. Consider for post-merge cleanup.

---

### Category 3: Not Rescuable (Obsolete or Redundant)

#### 3.1 Lockfiles
**Location:** `UI/yarn.lock`, `Docs/pnpm-lock.yaml`

**Reason:** Will be regenerated on `pnpm install` / `yarn install`

---

#### 3.2 Deleted Files
**Location:** Various scripts/docs

**Files:**
- `docs/LABELS_STANDARD.md` (deleted in `update-docs`)
- `scripts/helm-docs-common.sh` (deleted)
- `scripts/validate-consistency.sh` (deleted)
- `list-docs.md` (deleted)

**Reason:** Potentially obsolete or superseded. Would require investigation to confirm if deletions are safe.

**Recommendation:** Keep in `main` until proven obsolete.

---

## Execution Plan (Cherry-Pick Strategy)

### Phase 1: Direct Integrations (Safe)
1. Copy `.github/` directory from `update-docs` → `main`
2. Copy `config.toml` from `update-docs` → `main`
3. Apply `docker-bake.hcl` diff
4. Copy `UI/packages/` directory
5. Copy `load-test-gateway.js`
6. Commit: `feat: integrate CI/CD pipeline, config management, and Backstage UI from PR #77`

### Phase 2: Task UX Improvements (Manual)
1. Create feature branch: `feat/task-ux-improvements`
2. For each `Task/*.yaml` and `Taskfile.yaml`:
   - Compare `main` vs `update-docs`
   - Add `internal: true` to low-level tasks
   - Preserve all `cmds:` logic from `main`
3. Add global `dotenv: [".env"]` to `Taskfile.yaml`
4. Test: `task --list` should show only user-facing tasks
5. Commit: `feat: improve Taskfile UX with internal flags (from PR #77)`

### Phase 3: Future Work (Deferred)
1. Create issue: "Reorganize docs structure (concepts → implementation)"
   - Reference: PR #77 (`update-docs` branch)
   - Rationale: Semantic clarity, logical grouping
   - Blockers: Conflicts with architecture/ content in `main`
   - Estimated effort: 4-6 hours
2. Create issue: "Audit deleted scripts from PR #77"
   - Files: `helm-docs-common.sh`, `validate-consistency.sh`
   - Action: Confirm if still needed or obsolete

---

## Verification Steps

After Phase 1:
- Run `task quality:check` to verify no regressions
- Test GitHub Actions in PR (CI should pass)
- Verify `config.toml` loads correctly: `task deploy` should read config
- Build Backstage UI: `cd UI && yarn install && yarn build`
- Run load test: `k6 run load-test-gateway.js` (once cluster is up)

After Phase 2:
- Run `task --list` → Should show ~15 user-facing tasks (not 40+)
- Run key tasks: `task deploy`, `task destroy`, `task quality:check`
- Verify `.env` loading works if present

---

## Summary Table (New Strategy)

| Component | `update-docs` Value | Rescue Strategy | Priority |
| :--- | :--- | :--- | :---: |
| **GitHub Actions** | Production CI/CD pipeline | **Direct copy** | **P0** |
| **config.toml** | Centralized configuration | **Direct copy** | **P0** |
| **docker-bake.hcl** | Multi-target builds | **Direct apply** | **P0** |
| **Backstage UI** | Complete implementation | **Direct copy** | **P0** |
| **load-test-gateway.js** | Load testing tool | **Direct copy** | **P1** |
| **Task `internal` flags** | Better UX | **Manual integration** | **P1** |
| **Docs restructure** | Semantic clarity | **Defer (create issue)** | **P2** |
| **Deleted scripts** | Potential cleanup | **Investigate first** | **P3** |

**Priority Legend:** P0 = Critical, P1 = High value, P2 = Future work, P3 = Nice to have

---

## Appendix: Detailed File Mapping (Historical Reference)

> **Note:** The mapping below was created for the original "merge main → update-docs" strategy. It's preserved for reference but is no longer the execution strategy.

### A. Documentation Structure Changes

#### A.1 Directory Reorganization
| Old Path (`main`) | New Path (`update-docs`) | Action |
| :--- | :--- | :--- |
| `Docs/src/content/docs/concepts/` | `Docs/src/content/docs/implementation/` | **Renamed** |
| `Docs/src/content/docs/components/` | `Docs/src/content/docs/implementation/components/` | **Moved** |

#### A.2 Concept Files → Implementation Files
| File in `main` (old path) | File in `update-docs` (new path) | Similarity | Action |
| :--- | :--- | :---: | :--- |
| `concepts/cicd.mdx` | `implementation/cicd.mdx` | 100% | Keep `update-docs` structure |
| `concepts/design-philosophy.mdx` | `implementation/design-philosophy.mdx` | 95% | Apply `main` content edits |
| `concepts/gitops-model.mdx` | `implementation/gitops-model.mdx` | 100% | Keep `update-docs` |
| `concepts/networking-gateway.mdx` | `implementation/networking-gateway.mdx` | 97% | Apply `main` content edits |
| `concepts/scheduling-nodepools.mdx` | `implementation/scheduling-nodepools.mdx` | 100% | Keep `update-docs` |
| `concepts/security-policy-model.mdx` | `implementation/security-policy-model.mdx` | 97% | Apply `main` content edits |
| `concepts/observability.mdx` | **DELETED in `update-docs`** | N/A | **Split into architecture/ files** |
| `concepts/index.mdx` | **DELETED in `update-docs`** | N/A | **New index created** |

#### A.3 Component Files → Implementation/Components Files
| File in `main` | File in `update-docs` | Similarity | Action |
| :--- | :--- | :---: | :--- |
| `components/cicd/argo-workflows.mdx` | `implementation/components/cicd/argo-workflows.mdx` | 89% | **Apply `main` content** |
| `components/cicd/index.mdx` | `implementation/components/cicd/index.mdx` | 100% | Keep |
| `components/cicd/sonarqube.mdx` | `implementation/components/cicd/sonarqube.mdx` | 92% | **Apply `main` content** |
| `components/developer-portal/backstage.mdx` | `implementation/components/developer-portal/backstage.mdx` | 100% | Keep |
| `components/developer-portal/index.mdx` | `implementation/components/developer-portal/index.mdx` | 100% | Keep |
| `components/eventing/argo-events.mdx` | `implementation/components/eventing/argo-events.mdx` | 96% | Apply edits |
| `components/eventing/index.mdx` | `implementation/components/eventing/index.mdx` | 100% | Keep |
| `components/infrastructure/argocd.mdx` | `implementation/components/infrastructure/argocd.mdx` | 90% | **Apply `main` content** |
| `components/infrastructure/cert-manager.mdx` | `implementation/components/infrastructure/cert-manager.mdx` | 93% | Apply edits |
| `components/infrastructure/cilium.mdx` | `implementation/components/infrastructure/cilium.mdx` | 94% | Apply edits |
| `components/infrastructure/external-secrets.mdx` | `implementation/components/infrastructure/external-secrets.mdx` | 92% | Apply edits |
| `components/infrastructure/gateway-api.mdx` | `implementation/components/infrastructure/gateway-api.mdx` | 94% | Apply edits |
| `components/infrastructure/index.mdx` | `implementation/components/infrastructure/index.mdx` | 100% | Keep |
| `components/infrastructure/vault.mdx` | `implementation/components/infrastructure/vault.mdx` | 92% | Apply edits |
| `components/observability/fluent-bit.mdx` | `implementation/components/observability/fluent-bit.mdx` | 87% | **Apply `main` content** |
| `components/observability/grafana.mdx` | `implementation/components/observability/grafana.mdx` | 95% | Apply edits |
| `components/observability/index.mdx` | `implementation/components/observability/index.mdx` | 100% | Keep |
| `components/observability/loki.mdx` | `implementation/components/observability/loki.mdx` | 88% | **Apply `main` content** |
| `components/observability/prometheus.mdx` | `implementation/components/observability/prometheus.mdx` | 89% | **Apply `main` content** |
| `components/observability/pyrra.mdx` | `implementation/components/observability/pyrra.mdx` | 95% | Apply edits |
| `components/policy/index.mdx` | `implementation/components/policy/index.mdx` | 100% | Keep |
| `components/policy/kyverno.mdx` | `implementation/components/policy/kyverno.mdx` | 91% | Apply edits |
| `components/policy/policy-reporter.mdx` | `implementation/components/policy/policy-reporter.mdx` | 90% | Apply edits |
| `components/security/index.mdx` | `implementation/components/security/index.mdx` | 100% | Keep |
| `components/security/trivy.mdx` | `implementation/components/security/trivy.mdx` | 91% | Apply edits |

**Note:** Files with similarity < 90% require **careful manual review** during merge.

#### A.4 Architecture Files (Heavy Changes in `main`)
These files in `architecture/` have **massive content additions** in `main` (100-250+ lines):

| File | Lines Added in `main` | Action |
| :--- | :---: | :--- |
| `architecture/applications.mdx` | +231 | **Accept `main` version** |
| `architecture/bootstrap.mdx` | +117 | **Accept `main` version** |
| `architecture/driven-by-events.mdx` | +236 | **Accept `main` version** |
| `architecture/infrastructure.mdx` | +188 | **Accept `main` version** |
| `architecture/observability.mdx` | **NEW** | **Accept `main` version** |
| `architecture/overview.mdx` | +142 | **Accept `main` version** |
| `architecture/policies.mdx` | +151 | **Accept `main` version** |
| `architecture/portal.mdx` | +258 | **Accept `main` version** |
| `architecture/secrets.mdx` | +144 | **Accept `main` version** |

**Plus 40+ new diagram files** (.d2 and .svg) in `assets/diagrams/architecture/` — **Accept all from `main`**.

### B. Task Files (Hybrid Merge Required)

All Task files have changes in **both branches**:

| File | `main` Changes | `update-docs` Changes | Strategy |
| :--- | :--- | :--- | :--- |
| `Taskfile.yaml` | New global tasks | Refactored structure, `internal` flags | **Hybrid: Structure from `update-docs` + Logic from `main`** |
| `Task/bootstrap.yaml` | 294 lines (new steps) | `internal: true` flags, cleanup | **Hybrid: Structure from `update-docs` + Steps from `main`** |
| `Task/docs.yaml` | Logic updates | Refactored params | **Hybrid** |
| `Task/image.yaml` | New commands | Structure cleanup | **Hybrid** |
| `Task/k3d.yaml` | K3d tweaks | Refactored params | **Hybrid** |
| `Task/quality.yaml` | New checks | Structure cleanup | **Hybrid** |
| `Task/stacks.yaml` | New stacks | Refactored structure | **Hybrid** |
| `Task/utils.yaml` | New utilities | Cleanup | **Hybrid** |
| `Task/_internal.yaml` | Modified | Modified | **Hybrid** |

**Critical:** Task files require **line-by-line manual merge** preserving:
- `internal: true` flags from `update-docs`
- New `cmds:` and logic from `main`

### C. Kubernetes Values (Favor `main`)

| File | Change Type | Action |
| :--- | :--- | :--- |
| `K8s/observability/kube-prometheus-stack/values.yaml` | `main`: symlink → real file (456 lines) | **Accept `main` version** |
| `K8s/observability/loki/values.yaml` | Modified in both | **Accept `main` version** |

**Rationale:** `main` contains critical SLO configurations, resource limits, and Alertmanager webhook configs required for platform stability.

### D. Diagram Assets (Renamed in `update-docs`)

**18 diagram pairs** (.d2 + .svg) moved from `concepts/` → `implementation/`:

```
assets/diagrams/concepts/backbone-loops.*           → assets/diagrams/implementation/backbone-loops.*
assets/diagrams/concepts/design-philosophy-flow.*   → assets/diagrams/implementation/design-philosophy-flow.*
assets/diagrams/concepts/gitops-appprojects-appsets.* → assets/diagrams/implementation/gitops-appprojects-appsets.*
assets/diagrams/concepts/gitops-bootstrap-vs-gitops.* → assets/diagrams/implementation/gitops-bootstrap-vs-gitops.*
assets/diagrams/concepts/gitops-eventing.*          → assets/diagrams/implementation/gitops-eventing.*
assets/diagrams/concepts/networking-big-picture.*   → assets/diagrams/implementation/networking-big-picture.*
assets/diagrams/concepts/networking-detailed-architecture.* → assets/diagrams/implementation/networking-detailed-architecture.*
assets/diagrams/concepts/node-scheduling-priorities.* → assets/diagrams/implementation/node-scheduling-priorities.*
assets/diagrams/concepts/scheduling-architecture.*  → assets/diagrams/implementation/scheduling-architecture.*
```

**Action:** Git will auto-detect renames (R100). No manual intervention required for these.
